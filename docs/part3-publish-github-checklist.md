# Part 3 Publish Checklist (GitHub + Dev.to)

## 1) Final content checks

- Confirm title, description, tags, and series in `docs/devto-blog-post-part3.md`
- Replace `cover_image` placeholder URL if you have a final image
- Verify Part 1 and Part 2 links are correct
- Ensure placeholder naming stays generic (`<APP_DB>.<APP_SCHEMA>`, `<EXEC_WAREHOUSE>`, roles)

## 2) Validate changed files

Expected files for this publish step:

- `docs/devto-blog-post-part3.md`
- `docs/part3-publish-github-checklist.md`

## 3) Commit and push

```powershell
git add docs/devto-blog-post-part3.md docs/part3-publish-github-checklist.md
git commit -m "docs: add Dev.to-ready Part 3 security/governance post"
git push origin main
```

## 4) Publish on Dev.to

- Create new post in Dev.to editor
- Paste full content from `docs/devto-blog-post-part3.md`
- Set `published: true` in frontmatter when ready
- Add final cover image
- Publish in the same series as Part 1 and Part 2

## 5) Post-publish update (optional)

- Add the live Part 3 URL back into repo docs/README references
- Share in project README changelog section
