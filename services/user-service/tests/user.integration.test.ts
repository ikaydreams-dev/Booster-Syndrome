import request from 'supertest';
import { expect } from 'chai';

describe('User Service Integration Tests', () => {
  const baseUrl = 'http://localhost:3001';

  describe('POST /api/v1/users', () => {
    it('should create a new user', async () => {
      const res = await request(baseUrl)
        .post('/api/v1/users')
        .send({
          email: 'newuser@example.com',
          username: 'newuser',
          firstName: 'New',
          lastName: 'User'
        });

      expect(res.status).to.equal(201);
      expect(res.body).to.have.property('id');
      expect(res.body.email).to.equal('newuser@example.com');
    });

    it('should reject duplicate email', async () => {
      const userData = {
        email: 'duplicate@example.com',
        username: 'user1'
      };

      await request(baseUrl).post('/api/v1/users').send(userData);

      const res = await request(baseUrl)
        .post('/api/v1/users')
        .send(userData);

      expect(res.status).to.equal(409);
    });

    it('should validate email format', async () => {
      const res = await request(baseUrl)
        .post('/api/v1/users')
        .send({
          email: 'invalid-email',
          username: 'testuser'
        });

      expect(res.status).to.equal(400);
    });
  });

  describe('GET /api/v1/users/:id', () => {
    it('should get user by id', async () => {
      const res = await request(baseUrl)
        .get('/api/v1/users/123');

      expect(res.status).to.equal(200);
      expect(res.body).to.have.property('id');
    });

    it('should return 404 for non-existent user', async () => {
      const res = await request(baseUrl)
        .get('/api/v1/users/999999');

      expect(res.status).to.equal(404);
    });
  });

  describe('PUT /api/v1/users/:id', () => {
    it('should update user profile', async () => {
      const res = await request(baseUrl)
        .put('/api/v1/users/123')
        .send({
          firstName: 'Updated',
          lastName: 'Name'
        });

      expect(res.status).to.equal(200);
      expect(res.body.firstName).to.equal('Updated');
    });
  });

  describe('DELETE /api/v1/users/:id', () => {
    it('should delete user', async () => {
      const res = await request(baseUrl)
        .delete('/api/v1/users/123');

      expect(res.status).to.equal(204);
    });
  });
});
