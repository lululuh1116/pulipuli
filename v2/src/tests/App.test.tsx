import { render, screen, waitFor, within } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { describe, expect, it } from 'vitest'
import { App } from '../app/App'

describe('PuliPuli v2 application foundation', () => {
  it('renders the app', () => {
    render(<App initialEntries={['/auth/login']} />)

    expect(screen.getByRole('heading', { name: '回到你的工作室' })).toBeInTheDocument()
    expect(screen.getByText('PULIPULI V2')).toBeInTheDocument()
  })

  it('switches workspace name and theme together', async () => {
    const user = userEvent.setup()
    render(<App initialEntries={['/app/pulipuli/today']} />)

    await screen.findByRole('heading', { name: '嗨，PuliPuli' })
    await user.selectOptions(screen.getByLabelText('切換工作空間'), 'yunlin-brand')

    expect(await screen.findByRole('heading', { name: '嗨，雲林品牌' })).toBeInTheDocument()
    await waitFor(() =>
      expect(document.querySelector('.app-shell')).toHaveAttribute(
        'data-workspace-theme',
        'yunlin',
      ),
    )
  })

  it('preserves the workspace id in workspace routes', () => {
    render(<App initialEntries={['/app/yunlin-brand/analytics']} />)

    expect(screen.getByRole('heading', { name: '分析' })).toBeInTheDocument()
    expect(screen.getByTestId('workspace-id')).toHaveTextContent(
      'Workspace scope · yunlin-brand',
    )
  })

  it('renders five bottom navigation destinations and navigates', async () => {
    const user = userEvent.setup()
    render(<App initialEntries={['/app/pulipuli/today']} />)

    const navigation = screen.getByRole('navigation', { name: '主要功能' })
    expect(within(navigation).getAllByRole('link')).toHaveLength(5)
    expect(within(navigation).getByRole('link', { name: '首頁' })).toHaveClass(
      'is-active',
    )

    await user.click(within(navigation).getByRole('link', { name: '顧客' }))
    expect(await screen.findByRole('heading', { name: '顧客' })).toBeInTheDocument()
  })
})
