package data

import (
	"database/sql"
)

type Models struct {
	Movies      MovieModel
	Permissions PermissionModel
	Tokens      TokenModel
	Users       UserModel
}

func NewModels(db *sql.DB) Models {
	return Models{
		Movies:      MovieModel{DB: db},
		Permissions: PermissionModel{DB: db},
		Tokens:      TokenModel{DB: db},
		Users:       UserModel{DB: db},
	}
}
