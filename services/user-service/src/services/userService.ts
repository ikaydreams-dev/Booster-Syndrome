import User, { IUser } from '../models/User';

export const createUser = async (data: Partial<IUser>): Promise<IUser> => {
  const user = new User(data);
  return await user.save();
};

export const getUserById = async (id: string): Promise<IUser | null> => {
  return await User.findById(id);
};

export const getUserByEmail = async (email: string): Promise<IUser | null> => {
  return await User.findOne({ email });
};

export const updateUser = async (
  id: string,
  data: Partial<IUser>
): Promise<IUser | null> => {
  return await User.findByIdAndUpdate(id, data, { new: true, runValidators: true });
};

export const deleteUser = async (id: string): Promise<void> => {
  await User.findByIdAndUpdate(id, { isActive: false });
};

export const getAllUsers = async (
  page: number = 1,
  limit: number = 10
): Promise<{ users: IUser[]; total: number }> => {
  const skip = (page - 1) * limit;

  const users = await User.find({ isActive: true })
    .limit(limit)
    .skip(skip)
    .sort({ createdAt: -1 });

  const total = await User.countDocuments({ isActive: true });

  return { users, total };
};
