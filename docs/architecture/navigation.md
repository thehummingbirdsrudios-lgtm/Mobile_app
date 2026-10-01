# Navigation

```mermaid
flowchart LR
  launch((Launch)) --> splash[/splash: protected, no data/]
  splash -->|no session / offline| login[/login/]
  splash -->|session verified| home
  login -->|sign-in ok| home
  subgraph Shell["Shell: bottom bar (<600dp) · rail (≥600dp)"]
    home[/home/]
    maal[/maal/]
    order[/order/]
    customer[/customer/]
    hisaab[/hisaab/]
    more[/more/] --> legal[/more/legal/:doc/]
  end
  more -->|logout| login
  subgraph Full["Full-screen routes (root navigator, above the tabs)"]
    search[/search/]
    navo[/navo-maal/]
    product[/product/:id · /product/new · /product/:id/edit/]
    cust[/customers/:id · /customers/new · …/edit · …/rates/]
    orders[/orders · /orders/:id · /cart · /quick-order/]
    ledger[/ledger/:customerId · …/pay/]
    settings[/settings/business · staff · audit · export · notifications/]
  end
  Shell --> Full
```

## Where routes live
Tabs hold only their list screens. Detail, editor and flow screens are
full-screen routes on the root navigator, so they can be opened from any tab,
from search or from a deep link with one `push`, and Back always returns to
where the user came from. (Pushing a tab's sub-route from a root route
duplicates page keys in go_router; found in testing and avoided by design.)
Modules never import screens of other modules: they call the `AppNavigator`
port (`core/navigation`), implemented by `GoRouterNavigator` with paths from
`AppRoutes`.

## Guards
`redirectFor(session, location)` in `app/lib/app/router.dart`:
- **Unknown** identity → `/splash` only. No business data is rendered.
- **Signed out** → `/login` for every route, deep links included.
- **Signed in** → `/splash` and `/login` redirect to `/home`; deep links are kept.

Malformed deep links (e.g. `/more/legal/unknown`, `/product/not-a-uuid`)
redirect to a safe screen; unknown paths show "This page does not exist".
They never crash. Ids in deep links are re-authorised by the server (RLS)
when the screen loads — routes never trust ids; another business's id simply
reads as "not found".

## Back behaviour
1. Keyboard open → Back closes the keyboard (platform).
2. Sheet or dialog open → Back closes it.
3. Pushed route (e.g. legal) → pop.
4. Root of a non-Home tab → go to Home (`AppShell` `PopScope`).
5. Home root → leave the app.

Unsaved work uses `UnsavedChangesGuard`. Only screens holding real unsaved
input ask, and the dialog states the consequence.

## Tabs and state
`StatefulShellRoute.indexedStack` keeps each tab's stack alive. Re-tapping
the active tab returns it to its root.

## Contextual actions (not separate modules)
WhatsApp appears where content lives: product → share, customer → WhatsApp,
order → send, bill → send, Hisaab → send, payment → receipt.
