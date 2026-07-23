import { createSlice, createAsyncThunk } from '@reduxjs/toolkit';
import { analyticsApi } from '../utils/api';

interface AnalyticsState {
  summary: any;
  loading: boolean;
  error: string | null;
}

const initialState: AnalyticsState = {
  summary: null,
  loading: false,
  error: null,
};

export const fetchAnalyticsSummary = createAsyncThunk(
  'analytics/fetchSummary',
  async ({ startDate, endDate }: { startDate: string; endDate: string }) => {
    const response = await analyticsApi.getAnalytics('', startDate, endDate);
    return response.data;
  }
);

const analyticsSlice = createSlice({
  name: 'analytics',
  initialState,
  reducers: {},
  extraReducers: (builder) => {
    builder
      .addCase(fetchAnalyticsSummary.pending, (state) => {
        state.loading = true;
      })
      .addCase(fetchAnalyticsSummary.fulfilled, (state, action) => {
        state.loading = false;
        state.summary = action.payload;
      })
      .addCase(fetchAnalyticsSummary.rejected, (state, action) => {
        state.loading = false;
        state.error = action.error.message || 'Failed to fetch analytics';
      });
  },
});

export default analyticsSlice.reducer;
