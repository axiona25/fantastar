export default async function LeaguePage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;
  return (
    <div className="p-4">
      <h1 className="text-xl font-semibold">Lega (placeholder)</h1>
      <p className="text-zinc-500">ID: {id}</p>
    </div>
  );
}
