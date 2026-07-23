import { Router } from 'express';
import {
  getUser,
  updateUser,
  deleteUser,
  getAllUsers,
} from '../controllers/userController';
import { validateUser } from '../middleware/validation';

const router = Router();

router.get('/', getAllUsers);
router.get('/:id', getUser);
router.put('/:id', validateUser, updateUser);
router.delete('/:id', deleteUser);

export default router;
