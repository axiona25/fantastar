"""
Test per i data provider: chiamate API reali, formato atteso, sample dati.
Eseguire con: pytest tests/test_data_providers.py -v
Da backend: pytest tests/test_data_providers.py -v
In Docker: docker-compose exec backend pytest tests/test_data_providers.py -v
"""
import pytest
from app.config import settings


@pytest.mark.asyncio
async def test_football_data_org_standings():
    """Football-Data.org: get_standings ritorna classifica con struttura attesa."""
    from app.data_providers.football_data_org import FootballDataOrgProvider

    if not settings.FOOTBALL_DATA_ORG_KEY:
        pytest.skip("FOOTBALL_DATA_ORG_KEY non configurata")
    provider = FootballDataOrgProvider(rate_limit=0)
    try:
        data = await provider.get_standings()
        assert isinstance(data, dict)
        assert "standings" in data or "competition" in data
        standings = data.get("standings") or data.get("standings", [])
        if standings:
            table = standings[0] if isinstance(standings[0], dict) else standings
            if isinstance(table, dict) and "table" in table:
                rows = table["table"]
                assert isinstance(rows, list)
                if rows:
                    sample = rows[0]
                    print("\n[Sample standings row]", sample)
        else:
            assert "competition" in data
        print("\n[Football-Data standings keys]", list(data.keys())[:10])
    finally:
        await provider.close()


@pytest.mark.asyncio
async def test_football_data_org_teams():
    """Football-Data.org: get_teams ritorna squadre con id e nome."""
    from app.data_providers.football_data_org import FootballDataOrgProvider

    if not settings.FOOTBALL_DATA_ORG_KEY:
        pytest.skip("FOOTBALL_DATA_ORG_KEY non configurata")
    provider = FootballDataOrgProvider(rate_limit=0)
    try:
        data = await provider.get_teams()
        assert isinstance(data, dict)
        teams = data.get("teams", [])
        assert isinstance(teams, list)
        if teams:
            sample = teams[0]
            assert "id" in sample or "name" in sample
            print("\n[Sample team]", {k: sample.get(k) for k in ("id", "name", "shortName", "tla") if sample.get(k)})
        print("\n[Teams count]", len(teams))
    finally:
        await provider.close()


@pytest.mark.asyncio
async def test_football_data_org_matches():
    """Football-Data.org: get_matches ritorna partite."""
    from app.data_providers.football_data_org import FootballDataOrgProvider

    if not settings.FOOTBALL_DATA_ORG_KEY:
        pytest.skip("FOOTBALL_DATA_ORG_KEY non configurata")
    provider = FootballDataOrgProvider(rate_limit=0)
    try:
        data = await provider.get_matches()
        assert isinstance(data, dict)
        matches = data.get("matches", [])
        assert isinstance(matches, list)
        if matches:
            sample = matches[0]
            print("\n[Sample match]", {k: sample.get(k) for k in ("id", "matchday", "status", "utcDate") if sample.get(k)})
        print("\n[Matches count]", len(matches))
    finally:
        await provider.close()


@pytest.mark.asyncio
async def test_thesportsdb_search_team():
    """TheSportsDB: search_team ritorna risultati con stemma/divise."""
    from app.data_providers.thesportsdb import TheSportsDBProvider

    provider = TheSportsDBProvider(rate_limit=0)
    try:
        data = await provider.search_team("Inter")
        assert isinstance(data, dict)
        teams = data.get("teams") or []
        if teams:
            sample = teams[0]
            print("\n[Sample TheSportsDB team]", {k: sample.get(k) for k in ("strTeam", "strTeamBadge", "idTeam") if sample.get(k)})
        assert isinstance(teams, list)
    finally:
        await provider.close()


@pytest.mark.asyncio
async def test_thesportsdb_standings():
    """TheSportsDB: get_standings ritorna tabella (backup)."""
    from app.data_providers.thesportsdb import TheSportsDBProvider

    provider = TheSportsDBProvider(rate_limit=0)
    try:
        data = await provider.get_standings()
        assert isinstance(data, dict)
        table = data.get("table") or data.get("standings") or []
        print("\n[TheSportsDB standings keys]", list(data.keys()))
        if table:
            print("\n[Sample standings row]", table[0] if isinstance(table[0], dict) else table[:1])
    finally:
        await provider.close()


@pytest.mark.asyncio
async def test_bzzoiro_leagues_or_events():
    """BZZoiro: get_leagues o get_events ritorna dati (API può variare)."""
    from app.data_providers.bzzoiro import BZZoiroProvider

    if not settings.BZZOIRO_KEY:
        pytest.skip("BZZOIRO_KEY non configurata")
    provider = BZZoiroProvider(rate_limit=0)
    try:
        try:
            data = await provider.get_leagues()
        except Exception:
            data = await provider.get_events()
        assert isinstance(data, dict)
        print("\n[BZZoiro response keys]", list(data.keys())[:15])
    finally:
        await provider.close()


@pytest.mark.asyncio
async def test_rss_fetch_all_feeds():
    """RSS: fetch_all_feeds ritorna lista articoli normalizzati."""
    from app.data_providers.rss_news import fetch_all_feeds

    articles = await fetch_all_feeds()
    assert isinstance(articles, list)
    for a in articles[:3]:
        assert "title" in a and "url" in a
        print("\n[Sample RSS article]", a.get("title", "")[:60], "|", a.get("source"))
    print("\n[RSS articles count]", len(articles))


@pytest.mark.asyncio
async def test_sync_manager_standings():
    """SyncManager: sync_standings usa Football-Data e ritorna classifica."""
    from app.data_providers.sync_manager import SyncManager

    if not settings.FOOTBALL_DATA_ORG_KEY:
        pytest.skip("FOOTBALL_DATA_ORG_KEY non configurata")
    manager = SyncManager()
    try:
        data = await manager.sync_standings()
        assert isinstance(data, dict)
        print("\n[SyncManager standings keys]", list(data.keys())[:8])
    finally:
        await manager.close()


@pytest.mark.asyncio
async def test_sync_manager_news():
    """SyncManager: sync_news ritorna articoli da tutti i feed."""
    from app.data_providers.sync_manager import SyncManager

    manager = SyncManager()
    try:
        articles = await manager.sync_news()
        assert isinstance(articles, list)
        print("\n[SyncManager news count]", len(articles))
    finally:
        await manager.close()
