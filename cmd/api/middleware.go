package main

import (
	"errors"
	"expvar"
	"fmt"
	"net"
	"net/http"
	"strconv"
	"strings"
	"sync"
	"time"

	"greenlight/internal/data"
	"greenlight/internal/validator"

	"github.com/felixge/httpsnoop"
	"golang.org/x/time/rate"
)

func (app *application) recoverPanic(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		defer func() {
			if err := recover(); err != nil {
				w.Header().Set("Connection", "close")
				app.serverErrorResponse(w, r, fmt.Errorf("%s", err))
			}
		}()

		next.ServeHTTP(w, r)
	})
}

func (app *application) rateLimit(next http.Handler) http.Handler {
	type client struct {
		limiter  *rate.Limiter
		lastSeen time.Time
	}

	var (
		mu      sync.Mutex
		clients = make(map[string]*client)
	)

	go func() {
		for {
			time.Sleep(time.Minute)

			mu.Lock()
			for ip, client := range clients {
				if time.Since(client.lastSeen) > 3*time.Minute {
					delete(clients, ip)
				}
			}
			mu.Unlock()
		}
	}()

	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if app.config.limiter.enabled {
			ip, _, err := net.SplitHostPort(r.RemoteAddr)
			if err != nil {
				app.serverErrorResponse(w, r, err)
				return
			}
			mu.Lock()
			if _, found := clients[ip]; !found {
				clients[ip] = &client{
					limiter: rate.NewLimiter(rate.Limit(app.config.limiter.rps), app.config.limiter.burst),
				}
			}
			clients[ip].lastSeen = time.Now()
			if !clients[ip].limiter.Allow() {
				mu.Unlock()
				app.rateLimitExceededResponse(w, r)
				return
			}
			mu.Unlock()
		}
		next.ServeHTTP(w, r)
	})
}

func (app *application) authenticate(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		// Add the "Vary: Authorization" header to the response. This indicates to any
		// caches that the response may vary based on the value of the Authorization
		// header in the request.
		w.Header().Add("Vary", "Authorization")

		// Retrieve the value of the Authorization header from the request. This will
		// return the empty string "" if there is no such header found.
		authorizationHeader := r.Header.Get("Authorization")

		// If there is no Authorization header found, use the contextSetUser() helper
		// that we just made to add the AnonymousUser to the request context. Then we
		// call the next handler in the chain and return without executing any of the
		// code below.
		if authorizationHeader == "" {
			r = app.contextSetUser(r, data.AnonymousUser)
			next.ServeHTTP(w, r)
			return
		}

		// Otherwise, we expect the value of the Authorization header to be in the format
		// "Bearer <token>". We try to split this into its constituent parts, and if the
		// header isn't in the expected format we return a 401 Unauthorized response
		// using the invalidAuthenticationTokenResponse() helper (which we will create
		// in a moment).
		headerParts := strings.Split(authorizationHeader, " ")
		if len(headerParts) != 2 || headerParts[0] != "Bearer" {
			app.invalidAuthenticationTokenResponse(w, r)
			return
		}

		// Extract the actual authentication token from the header parts.
		token := headerParts[1]

		// Validate the token to make sure it is in a sensible format.
		v := validator.New()

		// If the token isn't valid, use the invalidAuthenticationTokenResponse()
		// helper to send a response, rather than the failedValidationResponse() helper
		// that we'd normally use.
		if data.ValidateTokenPlaintext(v, token); !v.Valid() {
			app.invalidAuthenticationTokenResponse(w, r)
			return
		}

		// Retrieve the details of the user associated with the authentication token,
		// again calling the invalidAuthenticationTokenResponse() helper if no
		// matching record was found. IMPORTANT: Notice that we are using
		// ScopeAuthentication as the first parameter here.
		user, err := app.models.Users.GetForToken(data.ScopeAuthentication, token)
		if err != nil {
			switch {
			case errors.Is(err, data.ErrRecordNotFound):
				app.invalidAuthenticationTokenResponse(w, r)
			default:
				app.serverErrorResponse(w, r, err)
			}
			return
		}

		// Call the contextSetUser() helper to add the user information to the request
		// context.
		r = app.contextSetUser(r, user)

		next.ServeHTTP(w, r)
	})
}

// Create a new requireAuthenticatedUser() middleware to check that a user is not
// anonymous.
func (app *application) requireAuthenticatedUser(next http.HandlerFunc) http.HandlerFunc {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		user := app.contextGetUser(r)
		if user.IsAnonymous() {
			app.authenticationRequiredResponse(w, r)
			return
		}
		next.ServeHTTP(w, r)
	})
}

// Checks that a user is both authenticated and activated.
func (app *application) requireActivatedUser(next http.HandlerFunc) http.HandlerFunc {
	// Rather than returning this http.HandlerFunc we assign it to the variable fn.
	fn := http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		user := app.contextGetUser(r)

		// Check that a user is activated.
		if !user.Activated {
			app.inactiveAccountResponse(w, r)
			return
		}
		next.ServeHTTP(w, r)
	})
	// Wrap fn with the requireAuthenticatedUser() middleware before returning it.
	return app.requireAuthenticatedUser(fn)
}

func (app *application) requirePermission(code string, next http.HandlerFunc) http.HandlerFunc {
	fn := func(w http.ResponseWriter, r *http.Request) {
		user := app.contextGetUser(r)

		permissions, err := app.models.Permissions.GetAllForUser(user.ID)
		if err != nil {
			app.serverErrorResponse(w, r, err)
			return
		}

		if !permissions.Include(code) {
			app.notPermittedResponse(w, r)
			return
		}

		next.ServeHTTP(w, r)
	}

	return app.requireActivatedUser(fn)
}

// func (app *application) enableCORS(next http.Handler) http.Handler {
// 	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
// 		w.Header().Set("Access-Control-Allow-Origin", "*")

// 		next.ServeHTTP(w, r)
// 	})
// }

// func (app *application) enableCORS(next http.Handler) http.Handler {
// 	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
// 		// Add the "Vary: Origin" header.
// 		w.Header().Add("Vary", "Origin")
// 		// Get the value of the request's Origin header.
// 		origin := r.Header.Get("Origin")
// 		// Only run this if there's an Origin request header present AND at least one
// 		// trusted origin is configured.
// 		if origin != "" && len(app.config.cors.trustedOrigins) != 0 {
// 			// Loop through the list of trusted origins, checking to see if the request
// 			// origin exactly matches one of them.
// 			for i := range app.config.cors.trustedOrigins {
// 				if origin == app.config.cors.trustedOrigins[i] {
// 					// If there is a match, then set a "Access-Control-Allow-Origin"
// 					// response header with the request origin as the value.
// 					w.Header().Set("Access-Control-Allow-Origin", origin)
// 				}
// 			}
// 		}
// 		// Call the next handler in the chain.
// 		next.ServeHTTP(w, r)
// 	})
// }

func (app *application) enableCORS(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Header().Add("Vary", "Origin")
		// Add the "Vary: Access-Control-Request-Method" header.
		w.Header().Add("Vary", "Access-Control-Request-Method")
		origin := r.Header.Get("Origin")
		if origin != "" && len(app.config.cors.trustedOrigins) != 0 {
			for i := range app.config.cors.trustedOrigins {
				if origin == app.config.cors.trustedOrigins[i] {
					w.Header().Set("Access-Control-Allow-Origin", origin)
					// Check if the request has the HTTP method OPTIONS and contains the
					// "Access-Control-Request-Method" header. If it does, then we treat
					// it as a preflight request.
					if r.Method == http.MethodOptions && r.Header.Get("Access-Control-Request-Method") != "" {
						// Set the necessary preflight response headers, as discussed
						// previously.
						w.Header().Set("Access-Control-Allow-Methods", "OPTIONS, PUT, PATCH, DELETE")
						w.Header().Set("Access-Control-Allow-Headers", "Authorization, Content-Type")
						// Write the headers along with a 200 OK status and return from
						// the middleware with no further action.
						w.WriteHeader(http.StatusOK)
						return
					}
				}
			}
		}
		next.ServeHTTP(w, r)
	})
}

// func (app *application) metrics(next http.Handler) http.Handler {
// 	// Initialize the new expvar variables when the middleware chain is first built.
// 	totalRequestsReceived := expvar.NewInt("total_requests_received")
// 	totalResponsesSent := expvar.NewInt("total_responses_sent")
// 	totalProcessingTimeMicroseconds := expvar.NewInt("total_processing_time_μs")
// 	// The following code will be run for every request...
// 	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
// 		// Record the time that we started to process the request.
// 		start := time.Now()
// 		// Use the Add() method to increment the number of requests received by 1.
// 		totalRequestsReceived.Add(1)
// 		// Call the next handler in the chain.
// 		next.ServeHTTP(w, r)
// 		// On the way back up the middleware chain, increment the number of responses
// 		// sent by 1.
// 		totalResponsesSent.Add(1)
// 		// Calculate the number of microseconds since we began to process the request,
// 		// then increment the total processing time by this amount.
// 		duration := time.Now().Sub(start).Microseconds()
// 		totalProcessingTimeMicroseconds.Add(duration)
// 	})
// }

func (app *application) metrics(next http.Handler) http.Handler {
	totalRequestsReceived := expvar.NewInt("total_requests_received")
	totalResponsesSent := expvar.NewInt("total_responses_sent")
	totalProcessingTimeMicroseconds := expvar.NewInt("total_processing_time_μs")
	// Declare a new expvar map to hold the count of responses for each HTTP status
	// code.
	totalResponsesSentByStatus := expvar.NewMap("total_responses_sent_by_status")
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		// Increment the requests received count, like before.
		totalRequestsReceived.Add(1)
		// Call the httpsnoop.CaptureMetrics() function, passing in the next handler in
		// the chain along with the existing http.ResponseWriter and http.Request. This
		// returns the metrics struct that we saw above.
		metrics := httpsnoop.CaptureMetrics(next, w, r)
		// Increment the response sent count, like before.
		totalResponsesSent.Add(1)
		// Get the request processing time in microseconds from httpsnoop and increment
		// the cumulative processing time.
		totalProcessingTimeMicroseconds.Add(metrics.Duration.Microseconds())
		// Use the Add() method to increment the count for the given status code by 1.
		// Note that the expvar map is string-keyed, so we need to use the strconv.Itoa()
		// function to convert the status code (which is an integer) to a string.
		totalResponsesSentByStatus.Add(strconv.Itoa(metrics.Code), 1)
	})
}
