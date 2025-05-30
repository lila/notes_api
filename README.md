# Notes API

A REST API for managing user notes with CRUD operations, built with Dart and Google Firestore.

## Features

- **CRUD Operations**: Create, Read, Update, Delete notes
- **RESTful API**: Standard HTTP methods and status codes
- **Firestore Integration**: Google Cloud Firestore for data persistence
- **Containerized**: Docker support for easy deployment
- **Cloud Run Ready**: Optimized for Google Cloud Run deployment
- **Comprehensive Logging**: Request/response logging with different levels
- **CORS Support**: Cross-origin resource sharing for web applications
- **Input Validation**: Robust validation for all inputs
- **Error Handling**: Consistent error responses
- **Health Checks**: Built-in health check endpoint

## API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/health` | Health check |
| GET | `/api/notes` | Get all notes |
| GET | `/api/notes/{id}` | Get note by ID |
| POST | `/api/notes` | Create new note |
| PUT | `/api/notes/{id}` | Update existing note |
| DELETE | `/api/notes/{id}` | Delete note |
| GET | `/api/notes/search?q={query}` | Search notes |

## Data Model

```json
{
  "id": "string",
  "title": "string",
  "content": "string", 
  "createdAt": "ISO8601 timestamp",
  "updatedAt": "ISO8601 timestamp"
}
```

## Quick Start

### Prerequisites

- [Dart SDK](https://dart.dev/get-dart) 3.7 or later
- [Google Cloud Project](https://cloud.google.com/) with Firestore enabled
- [Docker](https://www.docker.com/) (optional, for containerization)

### Local Development

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd notes_api
   ```

2. **Install dependencies**
   ```bash
   dart pub get
   ```

3. **Set up environment variables**
   ```bash
   cp .env.example .env
   # Edit .env with your configuration
   ```

4. **Configure Google Cloud credentials**
   ```bash
   # Set up Application Default Credentials
   gcloud auth application-default login
   
   # Or set the service account key file
   export GOOGLE_APPLICATION_CREDENTIALS="path/to/service-account-key.json"
   ```

5. **Run the server**
   ```bash
   dart run bin/server.dart
   ```

6. **Test the API**
   ```bash
   curl http://localhost:8080/health
   ```

### Running Tests

```bash
dart test
```

### Docker Deployment

1. **Build the Docker image**
   ```bash
   docker build -t notes-api .
   ```

2. **Run the container**
   ```bash
   docker run -p 8080:8080 \
     -e GOOGLE_CLOUD_PROJECT_ID=your-project-id \
     -e GOOGLE_APPLICATION_CREDENTIALS=/app/credentials.json \
     -v /path/to/credentials.json:/app/credentials.json \
     notes-api
   ```

### Google Cloud Run Deployment

1. **Build and push to Container Registry**
   ```bash
   gcloud builds submit --tag gcr.io/PROJECT_ID/notes-api
   ```

2. **Deploy to Cloud Run**
   ```bash
   gcloud run deploy notes-api \
     --image gcr.io/PROJECT_ID/notes-api \
     --platform managed \
     --region us-central1 \
     --allow-unauthenticated \
     --set-env-vars GOOGLE_CLOUD_PROJECT_ID=PROJECT_ID
   ```

## Configuration

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `PORT` | Server port | `8080` |
| `ENVIRONMENT` | Environment (development/production) | `development` |
| `GOOGLE_CLOUD_PROJECT_ID` | Google Cloud Project ID | Required |
| `LOG_LEVEL` | Logging level | `info` |

### Google Cloud Setup

1. **Enable Firestore**
   ```bash
   gcloud firestore databases create --region=us-central1
   ```

2. **Create service account** (for production)
   ```bash
   gcloud iam service-accounts create notes-api-service
   gcloud projects add-iam-policy-binding PROJECT_ID \
     --member="serviceAccount:notes-api-service@PROJECT_ID.iam.gserviceaccount.com" \
     --role="roles/datastore.user"
   ```

## API Usage Examples

### Create a Note

```bash
curl -X POST http://localhost:8080/api/notes \
  -H "Content-Type: application/json" \
  -d '{
    "title": "My First Note",
    "content": "This is the content of my note"
  }'
```

### Get All Notes

```bash
curl http://localhost:8080/api/notes
```

### Get Note by ID

```bash
curl http://localhost:8080/api/notes/{note-id}
```

### Update a Note

```bash
curl -X PUT http://localhost:8080/api/notes/{note-id} \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Updated Title",
    "content": "Updated content"
  }'
```

### Delete a Note

```bash
curl -X DELETE http://localhost:8080/api/notes/{note-id}
```

### Search Notes

```bash
curl "http://localhost:8080/api/notes/search?q=search%20term"
```

## Development

### Project Structure

```
notes_api/
├── bin/
│   ├── server.dart              # Main server entry point
│   └── notes_api.dart           # CLI entry point
├── lib/
│   ├── models/
│   │   └── note.dart            # Note data model
│   ├── services/
│   │   └── firestore_service.dart # Firestore operations
│   ├── handlers/
│   │   └── notes_handler.dart   # HTTP request handlers
│   ├── middleware/
│   │   ├── cors_middleware.dart # CORS handling
│   │   └── logging_middleware.dart # Request logging
│   ├── utils/
│   │   └── response_utils.dart  # HTTP response helpers
│   └── notes_api.dart           # Library exports
├── test/
│   └── notes_api_test.dart      # Unit tests
├── Dockerfile                   # Container configuration
├── .env.example                 # Environment variables template
└── ARCHITECTURE.md              # Detailed architecture documentation
```

### Adding New Features

1. **Models**: Add new data models in `lib/models/`
2. **Services**: Add business logic in `lib/services/`
3. **Handlers**: Add HTTP handlers in `lib/handlers/`
4. **Middleware**: Add middleware in `lib/middleware/`
5. **Tests**: Add tests in `test/`

### Code Style

This project follows [Dart style guidelines](https://dart.dev/guides/language/effective-dart/style). Run the linter:

```bash
dart analyze
```

## Monitoring and Observability

### Health Check

The API includes a health check endpoint at `/health`:

```json
{
  "status": "healthy",
  "timestamp": "2025-05-30T13:30:00Z",
  "service": "notes-api",
  "version": "1.0.0",
  "environment": "development"
}
```

### Logging

The API includes comprehensive logging:
- Request/response logging
- Error tracking
- Performance metrics
- Structured log format

### Error Responses

All errors follow a consistent format:

```json
{
  "error": {
    "code": "ERROR_CODE",
    "message": "Human readable error message",
    "details": {
      "field": "fieldName",
      "value": "invalidValue"
    }
  }
}
```

## Security Considerations

- Input validation on all endpoints
- HTTPS enforcement in production
- CORS configuration
- Rate limiting (to be implemented)
- Authentication (to be implemented)

## Performance

- Efficient Firestore queries
- Connection pooling
- Request/response compression
- Auto-scaling with Cloud Run

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests
5. Run tests and linting
6. Submit a pull request

## License

This project is licensed under the MIT License.

## Support

For questions and support, please refer to the [ARCHITECTURE.md](ARCHITECTURE.md) file for detailed technical documentation.
