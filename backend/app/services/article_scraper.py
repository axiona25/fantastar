"""
Scraping articolo da URL: titolo, sottotitolo, autore, data, immagine, body HTML.
Usa httpx + BeautifulSoup; estrazione generica (og:*, article, main, ecc.).
Pulizia body: solo tag consentiti (p, h2, h3, img, blockquote, ul, ol, li, a),
rimozione nav/header/footer/sidebar/menu/widget/social/comment/ad e testo "Skip to content".
Titolo e subtitle vengono puliti da tag HTML (clean_html).
"""
import re
from urllib.parse import urljoin

import httpx
from bs4 import BeautifulSoup

from app.utils.html_utils import clean_html

# Tag da rimuovere sempre (non tenere il contenuto)
STRIP_TAGS = {"script", "style", "nav", "header", "footer", "aside", "iframe"}

# Classi da rimuovere (elementi con class che contiene una di queste)
STRIP_CLASS_PATTERN = re.compile(
    r"nav|menu|sidebar|widget|social|share|comment|related|ad|cookie",
    re.I,
)

# Tag consentiti nel body finale (il resto viene unwrappato)
ALLOWED_BODY_TAGS = {"p", "h2", "h3", "img", "blockquote", "ul", "ol", "li", "a"}

# Testo da rimuovere (Skip to content, ecc.)
SKIP_TEXT_PATTERN = re.compile(
    r"^\s*Skip\s+to\s+content.*$|^\s*Vai\s+al\s+contenuto.*$",
    re.I | re.MULTILINE,
)


def _should_strip_by_class(tag) -> bool:
    if tag is None or not hasattr(tag, "get"):
        return False
    if not tag.get("class"):
        return False
    cls = " ".join(tag.get("class", []))
    return bool(STRIP_CLASS_PATTERN.search(cls))


def _get_text_length(el) -> int:
    return len(el.get_text(strip=True))


def _find_article_container(soup):
    """Restituisce il contenitore principale: <article> se presente, altrimenti il div con più testo."""
    article = soup.find("article")
    if article:
        return article
    main = soup.find("main")
    if main:
        return main
    # Cerca il div con più testo (contenuto articolo)
    candidates = soup.find_all("div", role="main") or []
    if not candidates:
        candidates = soup.find_all(
            "div",
            class_=re.compile(
                r"article|post-content|entry-content|content|story-body|post-body",
                re.I,
            ),
        )
    if candidates:
        return max(candidates, key=_get_text_length)
    # Fallback: body
    body = soup.find("body")
    return body if body else soup


def _clean_body_tree(body_soup, base_url: str) -> None:
    """Rimuove tag e elementi non desiderati; converte URL relativi."""
    # Prima raccogli tutti i tag da rimuovere in una lista separata
    tags_to_remove = []
    for tag in body_soup.find_all(True):
        if tag is None or tag.name is None:
            continue
        # Rimuovi script, style, nav, aside, footer, header, iframe
        if tag.name in ("script", "style", "nav", "aside", "footer", "header", "iframe", "form", "noscript"):
            tags_to_remove.append(tag)
            continue
        # Rimuovi per classe
        classes = tag.get("class") if hasattr(tag, "get") and tag.attrs else []
        if classes:
            class_str = " ".join(classes).lower()
            strip_keywords = [
                "nav", "menu", "sidebar", "widget", "social", "share", "comment",
                "related", "ad-", "cookie", "newsletter", "popup", "modal", "banner",
            ]
            if any(kw in class_str for kw in strip_keywords):
                tags_to_remove.append(tag)

    # Poi rimuovi tutti in un secondo passaggio
    for tag in tags_to_remove:
        try:
            tag.decompose()
        except Exception:
            pass

    # Rimuovi [role='navigation'] e simili
    for tag in body_soup.find_all(attrs={"role": re.compile(r"navigation|banner|contentinfo", re.I)}):
        tag.decompose()

    # Rimuovi testo "Skip to content"
    for s in body_soup.find_all(string=re.compile(r"Skip\s+to\s+content|Vai\s+al\s+contenuto", re.I)):
        s.replace_with("")

    # Unwrap tag non consentiti (mantieni solo p, h2, h3, img, blockquote, ul, ol, li, a)
    for tag in reversed(list(body_soup.find_all(True))):
        if tag is None or tag.name is None:
            continue
        if tag.name not in ALLOWED_BODY_TAGS:
            try:
                tag.unwrap()
            except Exception:
                pass

    # Converti URL relativi in img e a
    for tag in body_soup.find_all("img", src=True):
        tag["src"] = urljoin(base_url, tag["src"])
    for tag in body_soup.find_all("a", href=True):
        href = tag["href"]
        if href and not href.startswith(("#", "mailto:", "javascript:")):
            tag["href"] = urljoin(base_url, href)


async def fetch_article(url: str, timeout: float = 15.0) -> dict:
    """
    Scarica la pagina e estrae titolo, subtitle, author, date, image_url, body_html.
    Body ripulito: solo tag p, h2, h3, img, blockquote, ul, ol, li, a.
    """
    result = {
        "title": "",
        "subtitle": "",
        "author": "",
        "date": "",
        "image_url": "",
        "body_html": "",
    }
    try:
        async with httpx.AsyncClient(
            follow_redirects=True,
            timeout=timeout,
            headers={"User-Agent": "FantastarApp/1.0 (News Reader)"},
        ) as client:
            resp = await client.get(url)
            resp.raise_for_status()
            html = resp.text
            base_url = str(resp.url)
    except Exception:
        return result

    soup = BeautifulSoup(html, "lxml")

    # Title: og:title > <title> > h1
    title_el = soup.find("meta", property="og:title")
    if title_el and title_el.get("content"):
        result["title"] = title_el["content"].strip()
    if not result["title"] and soup.title:
        result["title"] = soup.title.get_text(strip=True)
    if not result["title"]:
        h1 = soup.find("h1")
        if h1:
            result["title"] = h1.get_text(strip=True)

    # Subtitle: og:description o meta description o primo h2
    desc_el = soup.find("meta", property="og:description")
    if desc_el and desc_el.get("content"):
        result["subtitle"] = desc_el["content"].strip()
    if not result["subtitle"]:
        meta_desc = soup.find("meta", attrs={"name": "description"})
        if meta_desc and meta_desc.get("content"):
            result["subtitle"] = meta_desc["content"].strip()
    if not result["subtitle"]:
        h2 = soup.find("h2")
        if h2:
            result["subtitle"] = h2.get_text(strip=True)

    # Author
    author_el = soup.find("meta", attrs={"name": "author"})
    if author_el and author_el.get("content"):
        result["author"] = author_el["content"].strip()
    if not result["author"]:
        a = soup.find("a", rel="author")
        if a:
            result["author"] = a.get_text(strip=True)
    if not result["author"]:
        for cls in ("author", "byline", "post-author", "article__author"):
            el = soup.find(class_=re.compile(cls, re.I))
            if el:
                result["author"] = el.get_text(strip=True)[:200]
                break

    # Date
    pub_el = soup.find("meta", property="article:published_time")
    if pub_el and pub_el.get("content"):
        result["date"] = pub_el["content"].strip()
    if not result["date"]:
        time_el = soup.find("time", datetime=True)
        if time_el and time_el.get("datetime"):
            result["date"] = time_el["datetime"].strip()
    if not result["date"]:
        for cls in ("date", "published", "post-date", "article__date", "time"):
            el = soup.find(class_=re.compile(cls, re.I))
            if el:
                result["date"] = el.get_text(strip=True)[:100]
                break

    # Main image: og:image (quasi tutti i siti), twitter:image, prima <img> in <article>
    img_el = soup.find("meta", property="og:image")
    if img_el and img_el.get("content"):
        result["image_url"] = urljoin(base_url, img_el["content"].strip())
    if not result["image_url"]:
        twitter_img = soup.find("meta", attrs={"name": "twitter:image"}) or soup.find("meta", property="twitter:image")
        if twitter_img and twitter_img.get("content"):
            result["image_url"] = urljoin(base_url, twitter_img["content"].strip())
    if not result["image_url"]:
        article_ctx = soup.find("article") or soup.find("main") or soup
        img = article_ctx.find("img", src=True)
        if img and img.get("src"):
            result["image_url"] = urljoin(base_url, img["src"].strip())

    # Body: contenitore articolo poi pulizia
    container = _find_article_container(soup)
    if container:
        body_soup = BeautifulSoup(str(container), "lxml")
        _clean_body_tree(body_soup, base_url)
        result["body_html"] = str(body_soup).strip()

    if not result["body_html"]:
        body_soup = BeautifulSoup(html, "lxml")
        for tag in body_soup.find_all(["script", "style", "nav", "header", "footer", "aside"]):
            tag.decompose()
        body_el = body_soup.find("body") or body_soup
        _clean_body_tree(body_el, base_url)
        result["body_html"] = str(body_el).strip()

    # Pulizia titolo e subtitle da eventuali tag/entities
    result["title"] = clean_html(result["title"])
    result["subtitle"] = clean_html(result["subtitle"])

    return result
