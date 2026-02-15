import { PlayerDetailContent } from "./PlayerDetailContent";

export default async function PlayerPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;
  return <PlayerDetailContent id={id} />;
}
