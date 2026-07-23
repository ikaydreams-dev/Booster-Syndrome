# Troubleshooting Guide

## Common Issues

### Services Won't Start

#### Problem: Port already in use
```
Error: Port 8000 is already in use
```

**Solution:**
```bash
# Check what's using the port
lsof -i :8000

# Kill the process
kill -9 <PID>

# Or use the utility script
./scripts/utilities/check-ports.sh
```

#### Problem: Database connection refused
```
Error: Connection refused to localhost:5432
```

**Solution:**
1. Check if PostgreSQL is running:
```bash
docker ps | grep postgres
```

2. Start the database:
```bash
docker-compose up -d postgres
```

### Build Failures

#### Rust Build Errors
```bash
# Clear the build cache
cargo clean

# Update dependencies
cargo update

# Rebuild
cargo build
```

#### Node Build Errors
```bash
# Clear node_modules
rm -rf node_modules package-lock.json

# Reinstall
npm install
```

#### Python Build Errors
```bash
# Recreate virtual environment
rm -rf venv
python -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```

### Runtime Issues

#### High Memory Usage
- Check for memory leaks
- Increase container limits
- Enable connection pooling
- Review caching strategy

#### Slow Response Times
- Check database indexes
- Enable caching
- Review query performance
- Scale horizontally

#### Authentication Failures

**JWT Token Invalid:**
```
Error: 401 Unauthorized - Invalid token
```

**Solutions:**
1. Check token expiration
2. Verify JWT_SECRET matches across services
3. Clear expired sessions from Redis

### Docker Issues

#### Container Won't Start
```bash
# View logs
docker-compose logs service-name

# Restart service
docker-compose restart service-name

# Rebuild
docker-compose up -d --build service-name
```

#### Volume Permission Issues
```bash
# Fix permissions
chmod -R 755 ./data

# Or run with proper user
docker-compose up --user $(id -u):$(id -g)
```

### Database Issues

#### Migration Failures
```bash
# Rollback migration
# Check migration status
# Rerun migrations
./scripts/migrations/run.sh
```

#### Connection Pool Exhausted
- Increase pool size
- Check for connection leaks
- Add connection timeouts

### Frontend Issues

#### Build Fails
```bash
# Clear cache
rm -rf .vite
npm run build
```

#### Hot Reload Not Working
```bash
# Check file watchers
sysctl fs.inotify.max_user_watches

# Increase if needed
echo fs.inotify.max_user_watches=524288 | sudo tee -a /etc/sysctl.conf
```

## Debug Mode

Enable debug logging:
```bash
# Rust
RUST_LOG=debug cargo run

# Node
DEBUG=* npm run dev

# Python
LOG_LEVEL=DEBUG python main.py

# Go
export DEBUG=true
```

## Getting Help

1. Check logs: `docker-compose logs -f`
2. Review documentation
3. Search GitHub issues
4. Create new issue with:
   - Error message
   - Steps to reproduce
   - Environment details
   - Relevant logs
