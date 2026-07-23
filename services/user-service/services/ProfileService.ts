import { UserModel, IUserDocument } from '../models/UserModel';
import { ObjectId } from 'mongodb';

export class ProfileService {
  async getProfile(userId: string): Promise<IUserDocument | null> {
    try {
      const user = await UserModel.findById(userId).select('-__v');
      return user;
    } catch (error) {
      throw new Error(`Failed to get profile: ${error}`);
    }
  }

  async updateProfile(
    userId: string,
    updates: Partial<IUserDocument>
  ): Promise<IUserDocument | null> {
    try {
      // Remove fields that shouldn't be updated
      delete updates.email;
      delete updates.username;
      delete updates._id;

      const user = await UserModel.findByIdAndUpdate(
        userId,
        { $set: updates },
        { new: true, runValidators: true }
      );

      return user;
    } catch (error) {
      throw new Error(`Failed to update profile: ${error}`);
    }
  }

  async uploadAvatar(userId: string, avatarUrl: string): Promise<void> {
    try {
      await UserModel.findByIdAndUpdate(userId, { avatarUrl });
    } catch (error) {
      throw new Error(`Failed to upload avatar: ${error}`);
    }
  }

  async searchUsers(query: string, limit: number = 20): Promise<IUserDocument[]> {
    try {
      const users = await UserModel.find({
        $or: [
          { username: { $regex: query, $options: 'i' } },
          { firstName: { $regex: query, $options: 'i' } },
          { lastName: { $regex: query, $options: 'i' } },
        ],
        isActive: true,
      })
        .limit(limit)
        .select('username firstName lastName avatarUrl');

      return users;
    } catch (error) {
      throw new Error(`Failed to search users: ${error}`);
    }
  }

  async getUserStats(userId: string): Promise<any> {
    try {
      const user = await UserModel.findById(userId);
      if (!user) {
        throw new Error('User not found');
      }

      // Calculate user statistics
      return {
        userId,
        joinedDate: user.createdAt,
        profileCompleteness: this.calculateProfileCompleteness(user),
      };
    } catch (error) {
      throw new Error(`Failed to get user stats: ${error}`);
    }
  }

  private calculateProfileCompleteness(user: IUserDocument): number {
    let completeness = 0;
    const fields = ['firstName', 'lastName', 'avatarUrl'];

    fields.forEach((field) => {
      if (user[field as keyof IUserDocument]) {
        completeness += 100 / fields.length;
      }
    });

    return Math.round(completeness);
  }
}

export default new ProfileService();
