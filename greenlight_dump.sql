--
-- PostgreSQL database dump
--

-- Dumped from database version 15.1 (Debian 15.1-1.pgdg110+1)
-- Dumped by pg_dump version 15.1 (Debian 15.1-1.pgdg110+1)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: citext; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS citext WITH SCHEMA public;


--
-- Name: EXTENSION citext; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION citext IS 'data type for case-insensitive character strings';


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: movies; Type: TABLE; Schema: public; Owner: greenlight
--

CREATE TABLE public.movies (
    id bigint NOT NULL,
    created_at timestamp(0) with time zone DEFAULT now() NOT NULL,
    title text NOT NULL,
    year integer NOT NULL,
    runtime integer NOT NULL,
    genres text[] NOT NULL,
    version integer DEFAULT 1 NOT NULL,
    CONSTRAINT genres_length_check CHECK (((array_length(genres, 1) >= 1) AND (array_length(genres, 1) <= 5))),
    CONSTRAINT movies_runtime_check CHECK ((runtime >= 0)),
    CONSTRAINT movies_year_check CHECK (((year >= 1888) AND ((year)::double precision <= date_part('year'::text, now()))))
);


ALTER TABLE public.movies OWNER TO greenlight;

--
-- Name: movies_id_seq; Type: SEQUENCE; Schema: public; Owner: greenlight
--

CREATE SEQUENCE public.movies_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.movies_id_seq OWNER TO greenlight;

--
-- Name: movies_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: greenlight
--

ALTER SEQUENCE public.movies_id_seq OWNED BY public.movies.id;


--
-- Name: permissions; Type: TABLE; Schema: public; Owner: greenlight
--

CREATE TABLE public.permissions (
    id bigint NOT NULL,
    code text NOT NULL
);


ALTER TABLE public.permissions OWNER TO greenlight;

--
-- Name: permissions_id_seq; Type: SEQUENCE; Schema: public; Owner: greenlight
--

CREATE SEQUENCE public.permissions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.permissions_id_seq OWNER TO greenlight;

--
-- Name: permissions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: greenlight
--

ALTER SEQUENCE public.permissions_id_seq OWNED BY public.permissions.id;


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: greenlight
--

CREATE TABLE public.schema_migrations (
    version bigint NOT NULL,
    dirty boolean NOT NULL
);


ALTER TABLE public.schema_migrations OWNER TO greenlight;

--
-- Name: tokens; Type: TABLE; Schema: public; Owner: greenlight
--

CREATE TABLE public.tokens (
    hash bytea NOT NULL,
    user_id bigint NOT NULL,
    expiry timestamp(0) with time zone NOT NULL,
    scope text NOT NULL
);


ALTER TABLE public.tokens OWNER TO greenlight;

--
-- Name: users; Type: TABLE; Schema: public; Owner: greenlight
--

CREATE TABLE public.users (
    id bigint NOT NULL,
    created_at timestamp(0) with time zone DEFAULT now() NOT NULL,
    name text NOT NULL,
    email public.citext NOT NULL,
    password_hash bytea NOT NULL,
    activated boolean NOT NULL,
    version integer DEFAULT 1 NOT NULL
);


ALTER TABLE public.users OWNER TO greenlight;

--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: greenlight
--

CREATE SEQUENCE public.users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.users_id_seq OWNER TO greenlight;

--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: greenlight
--

ALTER SEQUENCE public.users_id_seq OWNED BY public.users.id;


--
-- Name: users_permissions; Type: TABLE; Schema: public; Owner: greenlight
--

CREATE TABLE public.users_permissions (
    user_id bigint NOT NULL,
    permission_id bigint NOT NULL
);


ALTER TABLE public.users_permissions OWNER TO greenlight;

--
-- Name: movies id; Type: DEFAULT; Schema: public; Owner: greenlight
--

ALTER TABLE ONLY public.movies ALTER COLUMN id SET DEFAULT nextval('public.movies_id_seq'::regclass);


--
-- Name: permissions id; Type: DEFAULT; Schema: public; Owner: greenlight
--

ALTER TABLE ONLY public.permissions ALTER COLUMN id SET DEFAULT nextval('public.permissions_id_seq'::regclass);


--
-- Name: users id; Type: DEFAULT; Schema: public; Owner: greenlight
--

ALTER TABLE ONLY public.users ALTER COLUMN id SET DEFAULT nextval('public.users_id_seq'::regclass);


--
-- Data for Name: movies; Type: TABLE DATA; Schema: public; Owner: greenlight
--

COPY public.movies (id, created_at, title, year, runtime, genres, version) FROM stdin;
1	2023-01-30 08:10:49+00	Moana	2016	107	{animation,adventure}	1
2	2023-01-30 08:30:21+00	Black Panther	2018	134	{sci-fi,action,adventure}	2
4	2023-01-30 08:30:49+00	The Breakfast Club	1985	97	{comedy,drama}	4
\.


--
-- Data for Name: permissions; Type: TABLE DATA; Schema: public; Owner: greenlight
--

COPY public.permissions (id, code) FROM stdin;
1	movies:read
2	movies:write
\.


--
-- Data for Name: schema_migrations; Type: TABLE DATA; Schema: public; Owner: greenlight
--

COPY public.schema_migrations (version, dirty) FROM stdin;
6	f
\.


--
-- Data for Name: tokens; Type: TABLE DATA; Schema: public; Owner: greenlight
--

COPY public.tokens (hash, user_id, expiry, scope) FROM stdin;
\\xee3ee604fa2cd5b19a9bff401ee02371a202d1724f5bb83d8c3450372acb8ccb	1	2023-02-07 22:32:57+00	authentication
\\xca76c80b54a75c0893eb84a4548c663d579d9d33a322980d5063af0b0e798870	1	2023-02-07 23:06:39+00	authentication
\\x4ab4756c75ac79068ca30755ffe48ed8f3dcb70dd3b082e19323e259c7bf7cd6	1	2023-02-07 23:27:48+00	authentication
\\x9b143009d84cd214e8b73cb9d3e917dd0cbaef57efa7f21149b4522579128869	1	2023-02-07 23:27:59+00	authentication
\\x34c42b4539e30844bf877af68edd4f1fb46871a46db5a717252bfbcafaa2660b	7	2023-02-07 23:29:28+00	authentication
\\x637303498f0b48552dff9d5f0d203c5caa9cf84d8fae27791aac18f937fba9f2	1	2023-02-08 12:13:03+00	authentication
\.


--
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: greenlight
--

COPY public.users (id, created_at, name, email, password_hash, activated, version) FROM stdin;
3	2023-02-06 15:36:40+00	Carol Smith	carol@example.com	\\x243261243132243968474c7755362f615867306445744d3669766e352e656a55774a57482e474d396275535276324b4253634c6c544256546547586d	f	1
4	2023-02-06 15:38:13+00	Bob Jones	bob@example.com	\\x2432612431322479542e442e556a3244354f434f76426e57394e6c534f68544e69596346444e4d4f30484d7479325030764d6158386250304e397a2e	f	1
5	2023-02-06 16:31:02+00	Dave Smith	dave@example.com	\\x24326124313224546b466778532e79794b655a7461597a676938435a4f597333334d625853772e666b6b35356e7750456f616577354638476f70716d	f	1
6	2023-02-06 16:45:23+00	Edith Smith	edith@example.com	\\x2432612431322467756e42764d662f652f315875593739304d2f6f702e5655347a544c4839326c434a784930795a557544775472494a645776667a6d	f	1
7	2023-02-06 18:51:38+00	Faith Smith	faith@example.com	\\x2432612431322475695a4564784466454b444b68642e786570354138755039594b70597554632e7250567a4f474869324d36614f334d47616b482e57	t	6
1	2023-02-03 13:10:27+00	Alice Smith	alice@example.com	\\x243261243132247035667a796b724556536b33436a4e534362562e724f2f6a4f544b746d44744e7a336f586237334c75572f6561726a357474475a79	t	1
\.


--
-- Data for Name: users_permissions; Type: TABLE DATA; Schema: public; Owner: greenlight
--

COPY public.users_permissions (user_id, permission_id) FROM stdin;
3	1
4	1
5	1
6	1
7	1
1	1
7	2
\.


--
-- Name: movies_id_seq; Type: SEQUENCE SET; Schema: public; Owner: greenlight
--

SELECT pg_catalog.setval('public.movies_id_seq', 4, true);


--
-- Name: permissions_id_seq; Type: SEQUENCE SET; Schema: public; Owner: greenlight
--

SELECT pg_catalog.setval('public.permissions_id_seq', 2, true);


--
-- Name: users_id_seq; Type: SEQUENCE SET; Schema: public; Owner: greenlight
--

SELECT pg_catalog.setval('public.users_id_seq', 7, true);


--
-- Name: movies movies_pkey; Type: CONSTRAINT; Schema: public; Owner: greenlight
--

ALTER TABLE ONLY public.movies
    ADD CONSTRAINT movies_pkey PRIMARY KEY (id);


--
-- Name: permissions permissions_pkey; Type: CONSTRAINT; Schema: public; Owner: greenlight
--

ALTER TABLE ONLY public.permissions
    ADD CONSTRAINT permissions_pkey PRIMARY KEY (id);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: greenlight
--

ALTER TABLE ONLY public.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: tokens tokens_pkey; Type: CONSTRAINT; Schema: public; Owner: greenlight
--

ALTER TABLE ONLY public.tokens
    ADD CONSTRAINT tokens_pkey PRIMARY KEY (hash);


--
-- Name: users users_email_key; Type: CONSTRAINT; Schema: public; Owner: greenlight
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_email_key UNIQUE (email);


--
-- Name: users_permissions users_permissions_pkey; Type: CONSTRAINT; Schema: public; Owner: greenlight
--

ALTER TABLE ONLY public.users_permissions
    ADD CONSTRAINT users_permissions_pkey PRIMARY KEY (user_id, permission_id);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: greenlight
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: movies_genres_idx; Type: INDEX; Schema: public; Owner: greenlight
--

CREATE INDEX movies_genres_idx ON public.movies USING gin (genres);


--
-- Name: movies_title_idx; Type: INDEX; Schema: public; Owner: greenlight
--

CREATE INDEX movies_title_idx ON public.movies USING gin (to_tsvector('simple'::regconfig, title));


--
-- Name: tokens tokens_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: greenlight
--

ALTER TABLE ONLY public.tokens
    ADD CONSTRAINT tokens_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: users_permissions users_permissions_permission_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: greenlight
--

ALTER TABLE ONLY public.users_permissions
    ADD CONSTRAINT users_permissions_permission_id_fkey FOREIGN KEY (permission_id) REFERENCES public.permissions(id) ON DELETE CASCADE;


--
-- Name: users_permissions users_permissions_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: greenlight
--

ALTER TABLE ONLY public.users_permissions
    ADD CONSTRAINT users_permissions_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- PostgreSQL database dump complete
--

