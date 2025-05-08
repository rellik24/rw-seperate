```bash
curl -X POST http://localhost:8080/api/users \
  -H "Content-Type: application/json" \
  -d '{"name": "新用戶", "email": "user@example.com", "password": "secure123", "createdAt": "'"$(date +%Y-%m-%dT%H:%M:%S)"'", "updatedAt": "'"$(date +%Y-%m-%dT%H:%M:%S)"'"}'
```

get
```bash
curl http://localhost:8080/api/users/1
```

get by email
```bash
curl http://localhost:8080/api/users/email/user@example.com
```
