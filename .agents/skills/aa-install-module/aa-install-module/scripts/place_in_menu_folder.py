#!/usr/bin/env python
"""Place an installed Alliance Auth app's menu item inside a sidebar folder.

Usage:
    DJANGO_SETTINGS_MODULE=myauth.settings.local \
        /home/allianceserver/venv/auth/bin/python \
        place_in_menu_folder.py --app aa_forum --folder Informative [--order 9999]

Exit codes: 0 ok, 1 app menu item not found, 2 other error.
"""
import argparse
import sys


def main() -> int:
    parser = argparse.ArgumentParser(description="Place an AA app menu item into a sidebar folder.")
    parser.add_argument("--app", required=True, help="Django app label of the installed module (e.g. aa_forum)")
    parser.add_argument("--folder", required=True, help="Target folder text (creates if missing)")
    parser.add_argument("--order", type=int, default=9999, help="Order of the app item inside the folder")
    parser.add_argument("--icon", default="fa-solid fa-folder", help="FontAwesome classes for a NEW folder")
    args = parser.parse_args()

    try:
        import django
        django.setup()
    except Exception as exc:
        print(f"ERROR: django setup failed: {exc}", file=sys.stderr)
        return 2

    from allianceauth.hooks import get_hooks
    from allianceauth.menu.core import menu_item_hooks
    from allianceauth.menu.models import MenuItem

    target_hash = None
    for hook_cls in get_hooks("menu_item_hook"):
        hook_instance = hook_cls()
        module = hook_instance.__class__.__module__ or ""
        if module == args.app or module.startswith(args.app + "."):
            target_hash = menu_item_hooks.generate_hash(hook_instance)
            break

    if target_hash is None:
        print(f"ERROR: no menu_item_hook found for app '{args.app}'. Installed and in INSTALLED_APPS?",
              file=sys.stderr)
        return 1

    try:
        app_item = MenuItem.objects.get(hook_hash=target_hash)
    except MenuItem.DoesNotExist:
        from allianceauth.menu.templatetags.menu_menu_items import menu_items
        try:
            menu_items({"request": None})
        except Exception:
            pass
        try:
            app_item = MenuItem.objects.get(hook_hash=target_hash)
        except MenuItem.DoesNotExist:
            print(f"ERROR: MenuItem for app '{args.app}' (hash={target_hash}) not found in DB.",
                  file=sys.stderr)
            return 1

    folder = MenuItem.objects.filter(text=args.folder, hook_hash__isnull=True, url="").first()
    if folder is None:
        folder = MenuItem.objects.create(text=args.folder, classes=args.icon, order=9999)
        print(f"Created new folder: '{args.folder}' (id={folder.id})")
    else:
        print(f"Using existing folder: '{folder.text}' (id={folder.id})")

    if app_item.parent_id == folder.id:
        print(f"Already placed: '{app_item.text}' is inside '{folder.text}'. Nothing to do.")
        return 0

    app_item.parent = folder
    app_item.order = args.order
    app_item.save()
    print(f"Placed '{app_item.text}' (id={app_item.id}) into folder '{folder.text}' (id={folder.id}).")
    return 0


if __name__ == "__main__":
    sys.exit(main())