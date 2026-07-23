import { describe, it, expect, beforeAll, afterAll } from '@jest/globals';
import mongoose from 'mongoose';
import { UserModel } from '../models/UserModel';

describe('User Model Tests', () => {
  beforeAll(async () => {
    await mongoose.connect('mongodb://localhost:27017/test_db');
  });

  afterAll(async () => {
    await mongoose.connection.dropDatabase();
    await mongoose.connection.close();
  });

  it('should create a new user', async () => {
    const userData = {
      email: 'test@example.com',
      username: 'testuser',
      firstName: 'Test',
      lastName: 'User',
    };

    const user = new UserModel(userData);
    const savedUser = await user.save();

    expect(savedUser._id).toBeDefined();
    expect(savedUser.email).toBe(userData.email);
    expect(savedUser.username).toBe(userData.username);
  });

  it('should not create user with duplicate email', async () => {
    const userData = {
      email: 'duplicate@example.com',
      username: 'user1',
    };

    await new UserModel(userData).save();

    const duplicateUser = new UserModel({
      email: 'duplicate@example.com',
      username: 'user2',
    });

    await expect(duplicateUser.save()).rejects.toThrow();
  });

  it('should validate required fields', async () => {
    const invalidUser = new UserModel({});

    await expect(invalidUser.save()).rejects.toThrow();
  });

  it('should find user by email', async () => {
    const userData = {
      email: 'find@example.com',
      username: 'finduser',
    };

    await new UserModel(userData).save();

    const found = await UserModel.findOne({ email: 'find@example.com' });
    expect(found).not.toBeNull();
    expect(found?.username).toBe('finduser');
  });

  it('should update user information', async () => {
    const user = await new UserModel({
      email: 'update@example.com',
      username: 'updateuser',
    }).save();

    user.firstName = 'Updated';
    await user.save();

    const updated = await UserModel.findById(user._id);
    expect(updated?.firstName).toBe('Updated');
  });

  it('should soft delete user', async () => {
    const user = await new UserModel({
      email: 'delete@example.com',
      username: 'deleteuser',
    }).save();

    user.isActive = false;
    await user.save();

    const deleted = await UserModel.findById(user._id);
    expect(deleted?.isActive).toBe(false);
  });

  it('should count active users', async () => {
    await UserModel.create([
      { email: 'active1@example.com', username: 'active1', isActive: true },
      { email: 'active2@example.com', username: 'active2', isActive: true },
      { email: 'inactive@example.com', username: 'inactive', isActive: false },
    ]);

    const count = await UserModel.countDocuments({ isActive: true });
    expect(count).toBeGreaterThanOrEqual(2);
  });
});
