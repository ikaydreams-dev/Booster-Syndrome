import { Router } from 'express';
import UserController from '../controllers/UserController';

const router = Router();

// User CRUD routes
router.get('/users', UserController.getAllUsers);
router.get('/users/:id', UserController.getUserById);
router.post('/users', UserController.createUser);
router.put('/users/:id', UserController.updateUser);
router.delete('/users/:id', UserController.deleteUser);

// Additional user routes
router.get('/users/:id/profile', async (req, res) => {
  try {
    // Get detailed user profile
    res.json({ message: 'User profile' });
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch profile' });
  }
});

router.put('/users/:id/avatar', async (req, res) => {
  try {
    // Update user avatar
    res.json({ message: 'Avatar updated' });
  } catch (error) {
    res.status(500).json({ error: 'Failed to update avatar' });
  }
});

router.get('/users/:id/activity', async (req, res) => {
  try {
    // Get user activity log
    res.json({ message: 'User activity' });
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch activity' });
  }
});

export default router;
