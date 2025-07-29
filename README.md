## Beta Version

### ERD Link
- [erd diagram](https://dbdiagram.io/d/6883a607cca18e685cc5cc4a)

### Description
- This is a demo version with only basic functionality.
- The data warehouse schema is open for modifications.


### Essential files to be exists 
#### Creds
```txt
./creds
├── dev_bigquery.json
└── dev_postgres.json

0 directories, 2 files
```

postgres creds example
```json
{
    "db_uri": "postgresql+psycopg2://postgres:123456@localhost:5432/online_analytical_processing"
}
```

bigquery creds example
```json
{
  "type": "service_account",
  "project_id": "xxxxxx",
  "private_key_id": "xxxxxx",
  "private_key": "xxxxxx",
  "client_email": "xxxx",
  "client_id": "xxxxxx",
  "auth_uri": "https://accounts.google.com/o/oauth2/auth",
  "token_uri": "https://oauth2.googleapis.com/token",
  "auth_provider_x509_cert_url": "xxxxx",
  "client_x509_cert_url": "xxxx",
  "universe_domain": "googleapis.com"
}
```