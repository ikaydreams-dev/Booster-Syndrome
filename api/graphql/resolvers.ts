import { GraphQLResolveInfo } from 'graphql';

export const resolvers = {
  Query: {
    user: async (_: any, { id }: { id: string }, context: any) => {
      return context.dataSources.userAPI.getUser(id);
    },

    users: async (_: any, { page = 1, limit = 10 }: any, context: any) => {
      return context.dataSources.userAPI.getUsers(page, limit);
    },

    me: async (_: any, __: any, context: any) => {
      if (!context.user) throw new Error('Not authenticated');
      return context.dataSources.userAPI.getUser(context.user.id);
    },

    events: async (_: any, args: any, context: any) => {
      return context.dataSources.analyticsAPI.getEvents(args);
    },

    analytics: async (_: any, { startDate, endDate }: any, context: any) => {
      return context.dataSources.analyticsAPI.getAnalytics(startDate, endDate);
    },
  },

  Mutation: {
    login: async (_: any, { email, password }: any, context: any) => {
      return context.dataSources.authAPI.login(email, password);
    },

    register: async (_: any, { email, username, password }: any, context: any) => {
      return context.dataSources.authAPI.register(email, username, password);
    },

    updateUser: async (_: any, { id, input }: any, context: any) => {
      if (!context.user) throw new Error('Not authenticated');
      return context.dataSources.userAPI.updateUser(id, input);
    },

    trackEvent: async (_: any, { input }: any, context: any) => {
      return context.dataSources.analyticsAPI.trackEvent(input);
    },
  },

  User: {
    events: async (parent: any, { limit }: any, context: any) => {
      return context.dataSources.analyticsAPI.getUserEvents(parent.id, limit);
    },
  },
};

export default resolvers;
