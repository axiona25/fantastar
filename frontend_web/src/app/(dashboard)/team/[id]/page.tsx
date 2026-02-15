import { TeamDetailContent } from "./TeamDetailContent";

export default async function TeamPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;
  return <TeamDetailContent id={id} />;
}
