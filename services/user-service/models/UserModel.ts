import mongoose, { Schema, Document } from 'mongoose';

export interface IUserDocument extends Document {
  email: string;
  username: string;
  firstName?: string;
  lastName?: string;
  isActive: boolean;
  createdAt: Date;
  updatedAt: Date;
}

const userSchema = new Schema<IUserDocument>(
  {
    email: {
      type: String,
      required: true,
      unique: true,
      lowercase: true,
      trim: true,
    },
    username: {
      type: String,
      required: true,
      unique: true,
      trim: true,
    },
    firstName: String,
    lastName: String,
    isActive: {
      type: Boolean,
      default: true,
    },
  },
  {
    timestamps: true,
  }
);

export const UserModel = mongoose.model<IUserDocument>('User', userSchema);
