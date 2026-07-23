import { Request, Response } from 'express';
import { UserModel } from '../models/UserModel';

export class UserController {
  // Get all users
  async getAllUsers(req: Request, res: Response) {
    try {
      const { page = 1, limit = 10, search } = req.query;
      const skip = (Number(page) - 1) * Number(limit);

      const query: any = { isActive: true };
      if (search) {
        query.$or = [
          { username: { $regex: search, $options: 'i' } },
          { email: { $regex: search, $options: 'i' } },
        ];
      }

      const users = await UserModel.find(query)
        .skip(skip)
        .limit(Number(limit))
        .select('-__v')
        .sort({ createdAt: -1 });

      const total = await UserModel.countDocuments(query);

      res.json({
        users,
        pagination: {
          page: Number(page),
          limit: Number(limit),
          total,
          pages: Math.ceil(total / Number(limit)),
        },
      });
    } catch (error) {
      res.status(500).json({ error: 'Failed to fetch users' });
    }
  }

  // Get user by ID
  async getUserById(req: Request, res: Response) {
    try {
      const { id } = req.params;
      const user = await UserModel.findById(id).select('-__v');

      if (!user) {
        return res.status(404).json({ error: 'User not found' });
      }

      res.json(user);
    } catch (error) {
      res.status(500).json({ error: 'Failed to fetch user' });
    }
  }

  // Create new user
  async createUser(req: Request, res: Response) {
    try {
      const { email, username, firstName, lastName } = req.body;

      // Check if user already exists
      const existingUser = await UserModel.findOne({
        $or: [{ email }, { username }],
      });

      if (existingUser) {
        return res.status(409).json({ error: 'User already exists' });
      }

      const user = new UserModel({
        email,
        username,
        firstName,
        lastName,
      });

      await user.save();

      res.status(201).json(user);
    } catch (error) {
      res.status(500).json({ error: 'Failed to create user' });
    }
  }

  // Update user
  async updateUser(req: Request, res: Response) {
    try {
      const { id } = req.params;
      const updates = req.body;

      // Don't allow updating email or username
      delete updates.email;
      delete updates.username;

      const user = await UserModel.findByIdAndUpdate(id, updates, {
        new: true,
        runValidators: true,
      });

      if (!user) {
        return res.status(404).json({ error: 'User not found' });
      }

      res.json(user);
    } catch (error) {
      res.status(500).json({ error: 'Failed to update user' });
    }
  }

  // Delete user (soft delete)
  async deleteUser(req: Request, res: Response) {
    try {
      const { id } = req.params;

      const user = await UserModel.findByIdAndUpdate(
        id,
        { isActive: false },
        { new: true }
      );

      if (!user) {
        return res.status(404).json({ error: 'User not found' });
      }

      res.status(204).send();
    } catch (error) {
      res.status(500).json({ error: 'Failed to delete user' });
    }
  }
}

export default new UserController();
