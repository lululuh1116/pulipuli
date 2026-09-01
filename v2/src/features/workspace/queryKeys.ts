type QueryFilters = Record<string, string | number | boolean | undefined>

export const workspaceQueryKeys = {
  customers: (workspaceId: string) => ['customers', workspaceId] as const,
  appointments: (workspaceId: string, filters: QueryFilters = {}) =>
    ['appointments', workspaceId, filters] as const,
  transactions: (workspaceId: string, filters: QueryFilters = {}) =>
    ['transactions', workspaceId, filters] as const,
  today: (workspaceId: string) => ['today', workspaceId] as const,
}
