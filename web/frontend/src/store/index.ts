import { configureStore } from '@reduxjs/toolkit';
import authReducer from './slices/authSlice';
import userReducer from './slices/userSlice';
import analyticsReducer from './slices/analyticsSlice';

export const store = configureStore({
  reducer: {
    auth: authReducer,
    user: userReducer,
    analytics: analyticsReducer,
  },
});

export type RootState = ReturnType<typeof store.getState>;
export type AppDispatch = typeof store.dispatch;
