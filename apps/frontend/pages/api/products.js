// Serverless API route in Next.js that proxies to the internal gateway URL
export default async function handler(req, res){
  const gateway = process.env.GATEWAY_URL || 'http://gateway.ecom.svc.cluster.local'
  const r = await fetch(`${gateway}/api/products`)
  const data = await r.json()
  res.status(200).json(data)
}