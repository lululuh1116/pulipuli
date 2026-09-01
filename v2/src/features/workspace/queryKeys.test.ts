import { describe, expect, it } from 'vitest'
import { workspaceQueryKeys } from './queryKeys'

describe('workspace query key contract', () => {
  it('scopes every domain key by workspace id', () => {
    expect(workspaceQueryKeys.customers('pulipuli')).toEqual([
      'customers',
      'pulipuli',
    ])
    expect(workspaceQueryKeys.appointments('yunlin-brand', { month: '2026-09' })).toEqual([
      'appointments',
      'yunlin-brand',
      { month: '2026-09' },
    ])
    expect(workspaceQueryKeys.transactions('pulipuli', { type: 'income' })).toEqual([
      'transactions',
      'pulipuli',
      { type: 'income' },
    ])
  })
})
