// Simple storefront: list products from gateway via Next.js API route
import useSWR from 'swr'
const fetcher = (url) => fetch(url).then(r => r.json())

export default function Home(){
  const { data } = useSWR('/api/products', fetcher)
  return (
    <div style={{padding:20, fontFamily:'system-ui'}}>
      <h1>Next‑Gen Grocery</h1>
      <p>Fast, scalable, AI‑assisted e‑commerce on AKS</p>
      <ul>
        {(data || []).map(p => (
          <li key={p.id}>{p.name} — ${p.price}</li>
        ))}
      </ul>
    </div>
  )
}