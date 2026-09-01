import { useMemo } from 'react'
import {
  RouterProvider,
  createBrowserRouter,
  createMemoryRouter,
} from 'react-router'
import { AppProviders } from './AppProviders'
import { appRoutes } from './router'

type AppProps = {
  initialEntries?: string[]
}

export function App({ initialEntries }: AppProps) {
  const router = useMemo(
    () =>
      initialEntries
        ? createMemoryRouter(appRoutes, { initialEntries })
        : createBrowserRouter(appRoutes),
    [initialEntries],
  )

  return (
    <AppProviders>
      <RouterProvider router={router} />
    </AppProviders>
  )
}
