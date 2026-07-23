import { createSlice, PayloadAction } from '@reduxjs/toolkit';

interface AnalyticsState {
  events: any[];
  stats: any | null;
  loading: boolean;
}

const initialState: AnalyticsState = {
  events: [],
  stats: null,
  loading: false,
};

const analyticsSlice = createSlice({
  name: 'analytics',
  initialState,
  reducers: {
    setEvents: (state, action: PayloadAction<any[]>) => {
      state.events = action.payload;
    },
    setStats: (state, action: PayloadAction<any>) => {
      state.stats = action.payload;
    },
    setLoading: (state, action: PayloadAction<boolean>) => {
      state.loading = action.payload;
    },
  },
});

export const { setEvents, setStats, setLoading } = analyticsSlice.actions;
export default analyticsSlice.reducer;
