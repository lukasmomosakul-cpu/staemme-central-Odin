# Belegte Anfragen (Formular-/XHR-Mitschnitte)

## godbot-diagnose_2026-09-26_1408.txt

```
# TEIL C - FORMULAR-MITSCHNITT
######################################################################

======================================================================
# 1  ART: Klick
Zeitpunkt: 26.9.2026, 14:07:25
Adresse:   https://de259.die-staemme.de/game.php?village=38859&screen=overview
======================================================================

text=Belohnung (5) | onclick= | html=<a class="tab-link" data-tab="reward-tab">Belohnung                                                        <span id="reward-system-badge" class="badge"> (5)</span>
                                                    </a>

======================================================================
# 2  ART: Klick
Zeitpunkt: 26.9.2026, 14:07:28
Adresse:   #
======================================================================

text=Abholen | onclick= | html=<a href="#" class="btn btn-confirm-yes reward-system-claim-button" data-reward-id="1701878">Abholen</a>

======================================================================
# 3  ART: XHR
Zeitpunkt: 26.9.2026, 14:07:28
Adresse:   /game.php?village=38859&screen=new_quests&ajax=claim_reward
======================================================================

reward_id=1701878&h=35a874f3

======================================================================
# 4  ART: XHR-Antwort
Zeitpunkt: 26.9.2026, 14:07:28
Adresse:   /game.php?village=38859&screen=new_quests&ajax=claim_reward
======================================================================

HTTP 200 :: {"response":{"rewards":[{"id":1700393,"player_id":1577504441,"building":"wall","building_level":2,"status":"unlocked","reward":{"wood":150,"stone":150,"iron":100}}],"rewards_all":{"wall":{"ids":[1700393,1700492,1700849,1701370],"wood":600,"stone":600,"iron":400,"count":4}},"rewards_html":{"1700393":{"game_link":"\/game.php?village=38859&amp;screen=wall","image":"<img src=\"https:\/\/dsde.innogamescdn.com\/asset\/e94cf8a0\/graphic\/buildings\/mid\/wall1.webp\" title=\"\" alt=\"\" class=\"bmain_list_img\" \/>","name":"Wall"}},"unlockable_rewards":[{"building_level":9,"building":"main","game_link":"\/game.php?village=38859&amp;screen=main","image":"<img src=\"https:\/\/dsde.innogamescdn.com\/asset\/e94cf8a0\/graphic\/buildings\/mid\/main2.webp\" title=\"\" alt=\"\" class=\"bmain_list_img\" \/>","name":"Hauptgeb\u00e4ude"},{"building_level":6,"building":"barracks","game_link":"\/game.php?village=38859&amp;screen=barracks","image":"<img src=\"https:\/\/dsde.innogamescdn.com\/asset\/e94cf8a0\/graphic\/buildings\/mid\/barracks2.webp\" title=\"\" alt=\"\" class=\"bmain_list_img\" \/>","name":"Kaserne"},{"building_level":1,"building":"stable","game_link":"\/game.php?village=38859&amp;screen=stable","image":"<img src=\"https:\/\/dsde.innogamescdn.com\/asset\/e94cf8a0\/graphic\/buildings\/mid\/stable1.webp\" title=\"\" alt=\"\" class=\"bmain_list_img\" \/>","name":"Stall"},{"building_level":1,"building":"garage","game_link":"\/game.php?village=38859&amp;screen=garage","image":"<img src=\"https:\/\/dsde.innogamescdn.com\/asset\/e94cf8a0\/graphic\/buildings\/mid\/garage1.webp\" title=\"\" alt=\"\" class=\"bmain_list_img\" \/>","name":"Werkstatt"},{"building_level":1,"building":"watchtower","game_link":"\/game.php?village=38859&amp;screen=watchtower","image":"<img src=\"https:\/\/dsde.innogamescdn.com\/asset\/e94cf8a0\/graphic\/buildings\/mid\/watchtower1.webp\" title=\"\" alt=\"\" class=\"bmain_list_img\" \/>","name":"Wachturm"},{"building_level":1,"building":"snob","game_link":"\/game.php?village=38859&amp;screen=snob","image":"<img src=\"https:\/\/dsde.innogamescdn.com\/asset\/e94cf8a0\/graphic\/buildings\/mid\/snob1.webp\" title=\"\" alt=\"\" class=\"bmain_list_img\" \/>","name":"Adelshof"},{"building_level":2,"building":"smith","game_link":"\/game.php?village=38859&amp;screen=smith","image":"<img src=\"https:\/\/dsde.innogamescdn.com\/asset\/e94cf8a0\/graphic\/buildings\/mid\/smith1.webp\" title=\"\" alt=\"\" class=\"bmain_list_img\" \/>","name":"Schmiede"},{"building_level":2,"building":"market","game_link":"\/game.php?village=38859&amp;screen=market","image":"<img src=\"https:\/\/dsde.innogamescdn.com\/asset\/e94cf8a0\/graphic\/buildings\/mid\/market1.webp\" title=\"\" alt=\"\" class=\"bmain_list_img\" \/>","name":"Marktplatz"},{"building_level":11,"building":"wood","game_link":"\/game.php?village=38859&amp;screen=wood","image":"<img src=\"https:\/\/dsde.innogamescdn.com\/asset\/e94cf8a0\/graphic\/buildings\/mid\/wood2.webp\" title=\"\" alt=\"\" class=\"bmain_list_img\" \/>","name":"Holzf\u00e4llerlager"},{"building_level":11,"building":"stone","game_link":"\/game.php?village=38859&amp;screen=stone","image":"<img src=\"https:\/\/dsde.innogamescdn.com\/asset\/e94cf8a0\/graphic\/buildings\/mid\/stone2.webp\" title=\"\" alt=\"\" class=\"bmain_list_img\" \/>","name":"Lehmgrube"},{"building_level":9,"building":"iron","game_link":"\/game.php?village=38859&amp;screen=iron","image":"<img src=\"https:\/\/dsde.innogamescdn.com\/asset\/e94cf8a0\/graphic\/buildings\/mid\/iron1.webp\" title=\"\" alt=\"\" class=\"bmain_list_img\" \/>","name":"Eisenmine"},{"building_level":3,"building":"farm","game_link":"\/game.php?village=38859&amp;screen=farm","image":"<img src=\"https:\/\/dsde.innogamescdn.com\/asset\/e94cf8a0\/graphic\/buildings\/mid\/farm1.webp\" title=\"\" alt=\"\" class=\"bmain_list_img\" \/>","name":"Bauernhof"},{"building_level":6,"building":"storage","game_link":"\/game.php?village=38859&amp;screen=storage","image":"<img src=\"https:\/\/dsde.innogamescdn.com\/asset\/e94cf8a0\/graphic\/buildings\/mid\/storage1.webp\" title=\"\" alt=\"\" class=\"bmain_list_img\" \/>","name":"Speicher"},{"building_level":2,"building":"hide","game_link":"\/game.php?village=38859&amp;screen=hide","image":"<img src=\"https:\/\/dsde.innogamescdn.com\/asset\/e94cf8a0\/graphic\/buildings\/mid\/hide1.webp\" title=\"\" alt=\"\" class=\"bmain_list_img\" \/>","name":"Versteck"},{"building_level":6,"building":"wall","game_link":"\/game.php?village=38859&amp;screen=wall","image":"<img src=\"https:\/\/dsde.innogamescdn.com\/asset\/e94cf8a0\/graphic\/buildings\/mid\/wall2.webp\" title=\"\" alt=\"\" class=\"bmain_list_img\" \/>","name":"Wall"}],"unlocked_rewards_count":4,"claimed":{"id":1701878,"player_id":1577504441,"building":"main","building_level":8,"status":"unlocked","reward":{"wood":150,"stone":150,"iron":100}}},"game_data":{"player":{"id":1577504441,"name":"FetterOrk","ally":"0","ally_level":null,"ally_member_count":null,"sitter":"0","sleep_start":"0","sitter_type":"normal","sleep_end":"0","sleep_last":"0","email_valid":"1","villages":"1","incomings":"0","supports":0,"knight_location":"38859","knight_unit":"1820913072","rank":6357,"points":"245","date_started":"1790326410","is_guest":"0","confirmation_skipping_hash":"3149267717","quest_progress":"0","points_formatted":"245","rank_formatted":"6<span class=\"grey\">.<\/span>357","pp":"1905","new_ally_application":0,"new_ally_invite":"0","new_buddy_request":"0","new_daily_bonus":"0","new_forum_post":0,"new_post_notification":0,"new_igm":"0","new_items":"0","new_report":"0","new_quest":"1"},"quest":{"use_questlines":true},"features":{"Premium":{"possible":true,"active":false},"AccountManager":{"possible":false,"active":false},"FarmAssistent":{"possible":true,"active":false}},"village":{"id":38859,"name":"FetterOrk's Dorf","display_name":"FetterOrk's Dorf (306|547) K53","wood":1148,"wood_prod":0.051946091001298,"wood_float":1148,"stone":1111,"stone_prod":0.051946091001298,"stone_ …[gekuerzt]

======================================================================
# 5  ART: Klick
Zeitpunkt: 26.9.2026, 14:08:11
Adresse:   #
======================================================================

text=Abholen | onclick= | html=<a href="#" class="btn btn-confirm-yes reward-system-claim-button" data-reward-id="1700393">Abholen</a>

======================================================================
# 6  ART: XHR
Zeitpunkt: 26.9.2026, 14:08:11
Adresse:   /game.php?village=38859&screen=new_quests&ajax=claim_reward
======================================================================

reward_id=1700393&h=35a874f3

======================================================================
# 7  ART: XHR-Antwort
Zeitpunkt: 26.9.2026, 14:08:11
Adresse:   /game.php?village=38859&screen=new_quests&ajax=claim_reward
======================================================================

HTTP 200 :: {"response":{"rewards":[{"id":1700492,"player_id":1577504441,"building":"wall","building_level":3,"status":"unlocked","reward":{"wood":150,"stone":150,"iron":100}}],"rewards_all":{"wall":{"ids":[1700492,1700849,1701370],"wood":450,"stone":450,"iron":300,"count":3}},"rewards_html":{"1700492":{"game_link":"\/game.php?village=38859&amp;screen=wall","image":"<img src=\"https:\/\/dsde.innogamescdn.com\/asset\/e94cf8a0\/graphic\/buildings\/mid\/wall1.webp\" title=\"\" alt=\"\" class=\"bmain_list_img\" \/>","name":"Wall"}},"unlockable_rewards":[{"building_level":9,"building":"main","game_link":"\/game.php?village=38859&amp;screen=main","image":"<img src=\"https:\/\/dsde.innogamescdn.com\/asset\/e94cf8a0\/graphic\/buildings\/mid\/main2.webp\" title=\"\" alt=\"\" class=\"bmain_list_img\" \/>","name":"Hauptgeb\u00e4ude"},{"building_level":6,"building":"barracks","game_link":"\/game.php?village=38859&amp;screen=barracks","image":"<img src=\"https:\/\/dsde.innogamescdn.com\/asset\/e94cf8a0\/graphic\/buildings\/mid\/barracks2.webp\" title=\"\" alt=\"\" class=\"bmain_list_img\" \/>","name":"Kaserne"},{"building_level":1,"building":"stable","game_link":"\/game.php?village=38859&amp;screen=stable","image":"<img src=\"https:\/\/dsde.innogamescdn.com\/asset\/e94cf8a0\/graphic\/buildings\/mid\/stable1.webp\" title=\"\" alt=\"\" class=\"bmain_list_img\" \/>","name":"Stall"},{"building_level":1,"building":"garage","game_link":"\/game.php?village=38859&amp;screen=garage","image":"<img src=\"https:\/\/dsde.innogamescdn.com\/asset\/e94cf8a0\/graphic\/buildings\/mid\/garage1.webp\" title=\"\" alt=\"\" class=\"bmain_list_img\" \/>","name":"Werkstatt"},{"building_level":1,"building":"watchtower","game_link":"\/game.php?village=38859&amp;screen=watchtower","image":"<img src=\"https:\/\/dsde.innogamescdn.com\/asset\/e94cf8a0\/graphic\/buildings\/mid\/watchtower1.webp\" title=\"\" alt=\"\" class=\"bmain_list_img\" \/>","name":"Wachturm"},{"building_level":1,"building":"snob","game_link":"\/game.php?village=38859&amp;screen=snob","image":"<img src=\"https:\/\/dsde.innogamescdn.com\/asset\/e94cf8a0\/graphic\/buildings\/mid\/snob1.webp\" title=\"\" alt=\"\" class=\"bmain_list_img\" \/>","name":"Adelshof"},{"building_level":2,"building":"smith","game_link":"\/game.php?village=38859&amp;screen=smith","image":"<img src=\"https:\/\/dsde.innogamescdn.com\/asset\/e94cf8a0\/graphic\/buildings\/mid\/smith1.webp\" title=\"\" alt=\"\" class=\"bmain_list_img\" \/>","name":"Schmiede"},{"building_level":2,"building":"market","game_link":"\/game.php?village=38859&amp;screen=market","image":"<img src=\"https:\/\/dsde.innogamescdn.com\/asset\/e94cf8a0\/graphic\/buildings\/mid\/market1.webp\" title=\"\" alt=\"\" class=\"bmain_list_img\" \/>","name":"Marktplatz"},{"building_level":11,"building":"wood","game_link":"\/game.php?village=38859&amp;screen=wood","image":"<img src=\"https:\/\/dsde.innogamescdn.com\/asset\/e94cf8a0\/graphic\/buildings\/mid\/wood2.webp\" title=\"\" alt=\"\" class=\"bmain_list_img\" \/>","name":"Holzf\u00e4llerlager"},{"building_level":11,"building":"stone","game_link":"\/game.php?village=38859&amp;screen=stone","image":"<img src=\"https:\/\/dsde.innogamescdn.com\/asset\/e94cf8a0\/graphic\/buildings\/mid\/stone2.webp\" title=\"\" alt=\"\" class=\"bmain_list_img\" \/>","name":"Lehmgrube"},{"building_level":9,"building":"iron","game_link":"\/game.php?village=38859&amp;screen=iron","image":"<img src=\"https:\/\/dsde.innogamescdn.com\/asset\/e94cf8a0\/graphic\/buildings\/mid\/iron1.webp\" title=\"\" alt=\"\" class=\"bmain_list_img\" \/>","name":"Eisenmine"},{"building_level":3,"building":"farm","game_link":"\/game.php?village=38859&amp;screen=farm","image":"<img src=\"https:\/\/dsde.innogamescdn.com\/asset\/e94cf8a0\/graphic\/buildings\/mid\/farm1.webp\" title=\"\" alt=\"\" class=\"bmain_list_img\" \/>","name":"Bauernhof"},{"building_level":6,"building":"storage","game_link":"\/game.php?village=38859&amp;screen=storage","image":"<img src=\"https:\/\/dsde.innogamescdn.com\/asset\/e94cf8a0\/graphic\/buildings\/mid\/storage1.webp\" title=\"\" alt=\"\" class=\"bmain_list_img\" \/>","name":"Speicher"},{"building_level":2,"building":"hide","game_link":"\/game.php?village=38859&amp;screen=hide","image":"<img src=\"https:\/\/dsde.innogamescdn.com\/asset\/e94cf8a0\/graphic\/buildings\/mid\/hide1.webp\" title=\"\" alt=\"\" class=\"bmain_list_img\" \/>","name":"Versteck"},{"building_level":6,"building":"wall","game_link":"\/game.php?village=38859&amp;screen=wall","image":"<img src=\"https:\/\/dsde.innogamescdn.com\/asset\/e94cf8a0\/graphic\/buildings\/mid\/wall2.webp\" title=\"\" alt=\"\" class=\"bmain_list_img\" \/>","name":"Wall"}],"unlocked_rewards_count":3,"claimed":{"id":1700393,"player_id":1577504441,"building":"wall","building_level":2,"status":"unlocked","reward":{"wood":150,"stone":150,"iron":100}}},"game_data":{"player":{"id":1577504441,"name":"FetterOrk","ally":"0","ally_level":null,"ally_member_count":null,"sitter":"0","sleep_start":"0","sitter_type":"normal","sleep_end":"0","sleep_last":"0","email_valid":"1","villages":"1","incomings":"0","supports":0,"knight_location":"38859","knight_unit":"1820913072","rank":6357,"points":"245","date_started":"1790326410","is_guest":"0","confirmation_skipping_hash":"3149267717","quest_progress":"0","points_formatted":"245","rank_formatted":"6<span class=\"grey\">.<\/span>357","pp":"1905","new_ally_application":0,"new_ally_invite":"0","new_buddy_request":"0","new_daily_bonus":"0","new_forum_post":0,"new_post_notification":0,"new_igm":"0","new_items":"0","new_report":"0","new_quest":"1"},"quest":{"use_questlines":true},"features":{"Premium":{"possible":true,"active":false},"AccountManager":{"possible":false,"active":false},"FarmAssistent":{"possible":true,"active":false}},"village":{"id":38859,"name":"FetterOrk's Dorf","display_name":"FetterOrk's Dorf (306|547) K53","wood":1300,"wood_prod":0.051946091001298,"wood_float":1300,"stone":1263,"stone_prod":0.051946091001298,"stone_float":1 …[gekuerzt]
```

## godbot-diagnose_2026-09-26_1416.txt

```
# TEIL C - FORMULAR-MITSCHNITT
######################################################################

======================================================================
# 1  ART: Formular vorher
Zeitpunkt: 26.9.2026, 14:16:25
Adresse:   /game.php?village=23350&screen=barracks&action=train&mode=train
======================================================================

spear=1&h=cb84bc95&(kein benannter Absendeknopf erkennbar)

======================================================================
# 2  ART: XHR
Zeitpunkt: 26.9.2026, 14:16:25
Adresse:   /game.php?village=23350&screen=barracks&ajaxaction=train&mode=train&
======================================================================

units%5Bspear%5D=1&h=cb84bc95

======================================================================
# 3  ART: Formular nachher
Zeitpunkt: 26.9.2026, 14:16:25
Adresse:   /game.php?village=23350&screen=barracks&action=train&mode=train
======================================================================

spear=1&h=cb84bc95&(kein benannter Absendeknopf erkennbar)

======================================================================
# 4  ART: XHR-Antwort
Zeitpunkt: 26.9.2026, 14:16:25
Adresse:   /game.php?village=23350&screen=barracks&ajaxaction=train&mode=train&
======================================================================

HTTP 200 :: {"response":{"success":true,"msg":"Rekrutierung begonnen","resources":[1011,539,770,1011,539,770],"current_order":"<div class=\"current_prod_wrapper\">\n\t\t\t\t\t\n\t<div id=\"replace_barracks\">\n\t\t\t\t<table class=\"vis\">\n\t\t<tr>\n            <th class=\"nowrap\">Fertigstellung der n\u00e4chsten Einheit (Speertr\u00e4ger):<\/th>\n\t\t\t<th><span class=\"timer\">0:10:06<\/span><\/th>\n\t\t<\/tr>\n\t\t<\/table>\n\t\t\n\t\t<div class=\"trainqueue_wrap\" id=\"trainqueue_wrap_barracks\">\n\t\t\t<table class=\"vis\" style=\"width: 100%\">\n\t\t\t\t<tr>\n\t\t\t\t\t<th style=\"width: 25%\">Ausbildung<\/th>\n\t\t\t\t\t<th>Dauer<\/th>\n\t\t\t\t\t<th>Fertigstellung<\/th>\n                    <th style=\"width: 150px\">Abbruch *<\/th>\n\t\t\t\t\t\t\t\t\t<\/tr>\n\t\n\t\t\t\t\t\t\t\t<tr class=\"lit\">\n\t\t\t\t\t<td class=\"lit-item\">\n\t\t\t\t\t\t<div class=\"unit_sprite unit_sprite_smaller spear\"><\/div>\n\t\t\t\t\t\t1 Speertr\u00e4ger\n\t\t\t\t\t<\/td>\n\t\t\t\t\t<td class=\"lit-item\"><span class=\"timer\">0:10:06<\/span><\/td>\n\t\t\t\t\t<td class=\"lit-item\">heute um 14:26:31<\/td>\n\t\t\t\t\t<td class=\"lit-item\"><a class=\"btn btn-cancel\" onclick=\"return TrainOverview.cancelOrder(2771879)\" href=\"\/game.php?village=23350&amp;screen=barracks&amp;action=cancel&amp;id=2771879&amp;h=cb84bc95\">Abbrechen<\/a><\/td>\n\t\t\t\t\t\t\t\t\t<\/tr>\n\t\n\t\t\t\t\t\t\t\t<tbody id=\"trainqueue_barracks\">\n\t\t\n\t\t\t\t\t\t\n\t\t\t\t\t\t\n\t\t\t\t<\/tbody>\n\t\n\t\t\t<\/table>\n\t\t<\/div>\n        <div style=\"font-size: 7pt;\">\n                            * Anf\u00e4ngerschutz: Die Kosten f\u00fcr abgebrochene Rekrutierungen werden in voller H\u00f6he erstattet.\n                    <\/div>\n\t\t<br \/>\n\n\t\t\t<\/div>\n<\/div>","population":99},"game_data":{"player":{"id":1577505705,"name":"OmaImH\u00fchnerstall","ally":"0","ally_level":null,"ally_member_count":null,"sitter":"0","sleep_start":"0","sitter_type":"normal","sleep_end":"0","sleep_last":"0","email_valid": …[gekuerzt]

======================================================================
# 5  ART: XHR
Zeitpunkt: 26.9.2026, 14:16:26
Adresse:   /game.php?village=23350&screen=new_quests&ajax=quest_popup&tab=main-tab&quest=1205
======================================================================

(leer)

======================================================================
# 6  ART: XHR
Zeitpunkt: 26.9.2026, 14:16:26
Adresse:   /game.php?village=23350&screen=new_quests&ajax=mark_opened
======================================================================

quest_id=1205&h=cb84bc95

======================================================================
# 7  ART: XHR-Antwort
Zeitpunkt: 26.9.2026, 14:16:26
Adresse:   /game.php?village=23350&screen=new_quests&ajax=quest_popup&tab=main-tab&quest=1205
======================================================================

HTTP 200 :: {"response":{"dialog":"<div class=\"quest-popup-container\">\n    <div class=\"quest-popup-header\">\n        <div class=\"quest-popup-navbar\">\n            <ul>\n                                    <li class=\"qline-tab selected-tab\">\n                        <a class=\"tab-link\"\n                           data-tab=\"main-tab\">Hauptaufgaben                                                    <\/a>\n                    <\/li>\n                                    <li class=\"qline-tab\">\n                        <a class=\"tab-link\"\n                           data-tab=\"reward-tab\">Belohnung                                                        <span id=\"reward-system-badge\" class=\"badge\"><\/span>\n                                                    <\/a>\n                    <\/li>\n                            <\/ul>\n        <\/div>\n    <\/div>\n    <div class=\"quest-popup-body\">\n        <div class=\"tab active-tab\" id=\"main-tab\">\n            <div class=\"quest-popup-leftbar\">\n                <ul class=\"questline-list\">\n                                        <li>\n                        <a href=\"#\" id=\"questline-header-1\" class=\"questline-header\" style=\"background-image: url(\/graphic\/quests_new\/questline_1.png)\">\n                            <div class=\"questline-title\">Konstruktion<\/div>\n                        <\/a>\n                        <ul class=\"quests\">\n                                                                                                                                                                    <li class=\"quest-state quest-state-finished\">\n                                <a class=\"quest-link\" data-questline-id=\"1\" data-quest-id=\"1015\">Neu und verbessert<\/a>\n                            <\/li>\n                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    <\/ul>\n                    <\/li>\n                                        <li>\n                        <a href=\"#\" id=\"questline-header-2\" class=\"questline-header\" style=\"background-image: url(\/graphic\/quests_new\/questline_2.png)\">\n                            <div class=\"questline-title\">Farmen<\/div>\n                        <\/a>\n                        <ul class=\"quests\">\n                                                                                                            <li class=\"quest-state quest-state-finished\">\n                                <a class=\"quest-link\" data-questline-id=\"2\" data-quest-id=\"1205\">Zu deinen Diensten!<\/a>\n                            <\/li>\n                                                                                                                                                                                                                                                                                                                                            <\/ul>\n                    <\/li>\n                                        <li>\n                        <a href=\"#\" id=\"questline-header-13\" class=\"questline-header\" style=\"background-image: url(\/graphic\/quests_new\/questline_11.png)\">\n                            <div class=\"questline-title\">Reliquien<\/div>\n                        <\/a>\n                        <ul class=\"quests\">\n                                                                                <li class=\"quest-state quest-state-new\">\n                                <a class=\"quest-link\" data-questline-id=\"13\" data-quest-id=\"1925\">W\u00e4hle Deinen Schatz<\/a>\n                            <\/li>\n                                                                                                                                                                    <\/ul>\n                    <\/li>\n                                    <\/ul>\n            <\/div>\n            <div class=\"quest-popup-content\">\n                <header class=\"quest-title\">\n                    <h1>&nbsp<\/h1>\n                    <p>&nbsp;<\/p>\n                    <div class=\"reward\"><\/div>\n                <\/header>\n                <div class=\"quest-body\">\n                    <p class=\"quest-description\"><\/p>\n                    <div class=\"quest-goals-container\">\n                        <div class=\"quest-goals\"><\/div>\n                        <section class=\"quest-reward-summary hidden\">\n                            <div class=\"quest-reward-image\">\n                            <\/div>\n                            <div class=\"quest-reward-text\">\n                                <p class=\"text-center quest-reward-title\">Aufgaben-Belohnung<\/p>\n                                <p class=\"quest-reward-description\" style=\"font-weight: bold;\"><\/p>\n                            <\/div>\n                        <\/section>\n                        <br>\n                        <div class=\"complete-btn-container\">\n                            <div class=\"btn btn-confirm-yes status-btn hidden\">Aufgabe abschlie\u00dfen<\/div>\n                            <div class=\"skip-btn hidden btn\">Aufgabe \u00fcberspringen<\/div>\n                            <div class=\"skip-help\"><i>Auch wenn du diese Aufgabe \u00fcberspringst, kannst du die Belohnung trotzdem bekommen.<\/i><\/div>\n                        <\/div>\n                    <\/div>\n                <\/div>\n                <footer c …[gekuerzt]

======================================================================
# 8  ART: XHR-Antwort
Zeitpunkt: 26.9.2026, 14:16:26
Adresse:   /game.php?village=23350&screen=new_quests&ajax=mark_opened
======================================================================

HTTP 200 :: {"response":null,"game_data":{"player":{"id":1577505705,"name":"OmaImH\u00fchnerstall","ally":"0","ally_level":null,"ally_member_count":null,"sitter":"0","sleep_start":"0","sitter_type":"normal","sleep_end":"0","sleep_last":"0","email_valid":"1","villages":"1","incomings":"0","supports":0,"knight_location":null,"knight_unit":null,"rank":4124,"points":"120","date_started":"1790328937","is_guest":"0","confirmation_skipping_hash":"3149267717","quest_progress":"1","points_formatted":"120","rank_formatted":"4<span class=\"grey\">.<\/span>124","pp":"0","new_ally_application":0,"new_ally_invite":"0","new_buddy_request":"0","new_daily_bonus":"0","new_forum_post":0,"new_post_notification":0,"new_igm":"0","new_items":"0","new_report":"1","new_quest":"1"},"quest":{"use_questlines":true},"features":{"Premium":{"possible":true,"active":false},"AccountManager":{"possible":false,"active":false},"FarmAssistent":{"possible":true,"active":false}},"village":{"id":23350,"name":"OmaImH\u00fchnerstall's Dorf","display_name":"OmaImH\u00fchnerstall's Dorf (610|596) K56","wood":1011,"wood_prod":0.032466306875811,"wood_float":1011.0649326137516,"stone":539,"stone_prod":0.017739350635623,"stone_float":539.0354787012712,"iron":770,"iron_prod":0.015251547976909,"iron_float":770.0305030959538,"pop":99,"pop_max":240,"x":610,"y":596,"trader_away":0,"storage_max":2285,"bonus_id":null,"bonus":null,"buildings":{"main":"5","barracks":"2","stable":"0","garage":"0","snob":"0","smith":"0","place":"1","market":"0","wood":"10","stone":"6","iron":"5","farm":"1","storage":"5","hide":"1","wall":"0"},"player_id":1577505705,"modifications":0,"points":120,"last_res_tick":1790424987000,"coord":"610|596","is_farm_upgradable":true},"nav":{},"link_base":"\/game.php?village=23350&amp;screen=","link_base_pure":"\/game.php?village=23350&screen=","csrf":"cb84bc95","world":"de258","market":"de","RTL":false,"version":"e94cf8a0 release_8.436\n","majorVersion":"8.436","screen":"new_quests","mode":null,"device":"desktop","pregame":false,"units":["spear","sword","axe","spy","light","heavy","ram","catapult","snob"],"locale":"de_DE","group_id":0,"time_generated":1790424987273}} …[gekuerzt]

======================================================================
# 9  ART: XHR
Zeitpunkt: 26.9.2026, 14:16:34
Adresse:   /game.php?village=23350&screen=api&ajaxaction=quest_complete&quest=1205&skip=false
======================================================================

h=cb84bc95

======================================================================
# 10  ART: XHR-Antwort
Zeitpunkt: 26.9.2026, 14:16:35
Adresse:   /game.php?village=23350&screen=api&ajaxaction=quest_complete&quest=1205&skip=false
======================================================================

HTTP 200 :: {"response":{"reward":"","detailed":[]},"game_data":{"player":{"id":1577505705,"name":"OmaImH\u00fchnerstall","ally":"0","ally_level":null,"ally_member_count":null,"sitter":"0","sleep_start":"0","sitter_type":"normal","sleep_end":"0","sleep_last":"0","email_valid":"1","villages":"1","incomings":"0","supports":0,"knight_location":null,"knight_unit":null,"rank":4124,"points":"120","date_started":"1790328937","is_guest":"0","confirmation_skipping_hash":"3149267717","quest_progress":"1","points_formatted":"120","rank_formatted":"4<span class=\"grey\">.<\/span>124","pp":"0","new_ally_application":0,"new_ally_invite":"0","new_buddy_request":"0","new_daily_bonus":"0","new_forum_post":0,"new_post_notification":0,"new_igm":"0","new_items":"0","new_report":"1","new_quest":1},"quest":{"use_questlines":true},"features":{"Premium":{"possible":true,"active":false},"AccountManager":{"possible":false,"active":false},"FarmAssistent":{"possible":true,"active":false}},"village":{"id":23350,"name":"OmaImH\u00fchnerstall's Dorf","display_name":"OmaImH\u00fchnerstall's Dorf (610|596) K56","wood":1011,"wood_prod":0.032466306875811,"wood_float":1011.3246630687581,"stone":539,"stone_prod":0.017739350635623,"stone_float":539.1773935063562,"iron":770,"iron_prod":0.015251547976909,"iron_float":770.1525154797691,"pop":99,"pop_max":240,"x":610,"y":596,"trader_away":0,"storage_max":2285,"bonus_id":null,"bonus":null,"buildings":{"main":"5","barracks":"2","stable":"0","garage":"0","snob":"0","smith":"0","place":"1","market":"0","wood":"10","stone":"6","iron":"5","farm":"1","storage":"5","hide":"1","wall":"0"},"player_id":1577505705,"modifications":0,"points":120,"last_res_tick":1790424995000,"coord":"610|596","is_farm_upgradable":true},"nav":{},"link_base":"\/game.php?village=23350&amp;screen=","link_base_pure":"\/game.php?village=23350&screen=","csrf":"cb84bc95","world":"de258","market":"de","RTL":false,"version":"e94cf8a0 release_8.436\n","majorVersion":"8.436","screen":"api","mode":null,"device":"desktop","pregame":false,"units":["spear","sword","axe","spy","light","heavy","ram","catapult","snob"],"locale":"de_DE","group_id":0,"time_generated":1790424995492}} …[gekuerzt]

======================================================================
# 11  ART: XHR
Zeitpunkt: 26.9.2026, 14:16:37
Adresse:   /game.php?village=23350&screen=new_quests&ajax=questline_complete&id=2
======================================================================

h=cb84bc95
```

## godbot-diagnose_2026-09-27_2000.txt

```
# TEIL C - FORMULAR-MITSCHNITT
######################################################################

======================================================================
# 1  ART: Klick
Zeitpunkt: 26.9.2026, 14:07:25
Adresse:   https://de259.die-staemme.de/game.php?village=38859&screen=overview
======================================================================

text=Belohnung (5) | onclick= | html=<a class="tab-link" data-tab="reward-tab">Belohnung                                                        <span id="reward-system-badge" class="badge"> (5)</span>
                                                    </a>

======================================================================
# 2  ART: Klick
Zeitpunkt: 26.9.2026, 14:07:28
Adresse:   #
======================================================================

text=Abholen | onclick= | html=<a href="#" class="btn btn-confirm-yes reward-system-claim-button" data-reward-id="1701878">Abholen</a>

======================================================================
# 3  ART: XHR
Zeitpunkt: 26.9.2026, 14:07:28
Adresse:   /game.php?village=38859&screen=new_quests&ajax=claim_reward
======================================================================

reward_id=1701878&h=35a874f3

======================================================================
# 4  ART: XHR-Antwort
Zeitpunkt: 26.9.2026, 14:07:28
Adresse:   /game.php?village=38859&screen=new_quests&ajax=claim_reward
======================================================================

HTTP 200 :: {"response":{"rewards":[{"id":1700393,"player_id":1577504441,"building":"wall","building_level":2,"status":"unlocked","reward":{"wood":150,"stone":150,"iron":100}}],"rewards_all":{"wall":{"ids":[1700393,1700492,1700849,1701370],"wood":600,"stone":600,"iron":400,"count":4}},"rewards_html":{"1700393":{"game_link":"\/game.php?village=38859&amp;screen=wall","image":"<img src=\"https:\/\/dsde.innogamescdn.com\/asset\/e94cf8a0\/graphic\/buildings\/mid\/wall1.webp\" title=\"\" alt=\"\" class=\"bmain_list_img\" \/>","name":"Wall"}},"unlockable_rewards":[{"building_level":9,"building":"main","game_link":"\/game.php?village=38859&amp;screen=main","image":"<img src=\"https:\/\/dsde.innogamescdn.com\/asset\/e94cf8a0\/graphic\/buildings\/mid\/main2.webp\" title=\"\" alt=\"\" class=\"bmain_list_img\" \/>","name":"Hauptgeb\u00e4ude"},{"building_level":6,"building":"barracks","game_link":"\/game.php?village=38859&amp;screen=barracks","image":"<img src=\"https:\/\/dsde.innogamescdn.com\/asset\/e94cf8a0\/graphic\/buildings\/mid\/barracks2.webp\" title=\"\" alt=\"\" class=\"bmain_list_img\" \/>","name":"Kaserne"},{"building_level":1,"building":"stable","game_link":"\/game.php?village=38859&amp;screen=stable","image":"<img src=\"https:\/\/dsde.innogamescdn.com\/asset\/e94cf8a0\/graphic\/buildings\/mid\/stable1.webp\" title=\"\" alt=\"\" class=\"bmain_list_img\" \/>","name":"Stall"},{"building_level":1,"building":"garage","game_link":"\/game.php?village=38859&amp;screen=garage","image":"<img src=\"https:\/\/dsde.innogamescdn.com\/asset\/e94cf8a0\/graphic\/buildings\/mid\/garage1.webp\" title=\"\" alt=\"\" class=\"bmain_list_img\" \/>","name":"Werkstatt"},{"building_level":1,"building":"watchtower","game_link":"\/game.php?village=38859&amp;screen=watchtower","image":"<img src=\"https:\/\/dsde.innogamescdn.com\/asset\/e94cf8a0\/graphic\/buildings\/mid\/watchtower1.webp\" title=\"\" alt=\"\" class=\"bmain_list_img\" \/>","name":"Wachturm"},{"building_level":1,"building":"snob","game_link":"\/game.php?village=38859&amp;screen=snob","image":"<img src=\"https:\/\/dsde.innogamescdn.com\/asset\/e94cf8a0\/graphic\/buildings\/mid\/snob1.webp\" title=\"\" alt=\"\" class=\"bmain_list_img\" \/>","name":"Adelshof"},{"building_level":2,"building":"smith","game_link":"\/game.php?village=38859&amp;screen=smith","image":"<img src=\"https:\/\/dsde.innogamescdn.com\/asset\/e94cf8a0\/graphic\/buildings\/mid\/smith1.webp\" title=\"\" alt=\"\" class=\"bmain_list_img\" \/>","name":"Schmiede"},{"building_level":2,"building":"market","game_link":"\/game.php?village=38859&amp;screen=market","image":"<img src=\"https:\/\/dsde.innogamescdn.com\/asset\/e94cf8a0\/graphic\/buildings\/mid\/market1.webp\" title=\"\" alt=\"\" class=\"bmain_list_img\" \/>","name":"Marktplatz"},{"building_level":11,"building":"wood","game_link":"\/game.php?village=38859&amp;screen=wood","image":"<img src=\"https:\/\/dsde.innogamescdn.com\/asset\/e94cf8a0\/graphic\/buildings\/mid\/wood2.webp\" title=\"\" alt=\"\" class=\"bmain_list_img\" \/>","name":"Holzf\u00e4llerlager"},{"building_level":11,"building":"stone","game_link":"\/game.php?village=38859&amp;screen=stone","image":"<img src=\"https:\/\/dsde.innogamescdn.com\/asset\/e94cf8a0\/graphic\/buildings\/mid\/stone2.webp\" title=\"\" alt=\"\" class=\"bmain_list_img\" \/>","name":"Lehmgrube"},{"building_level":9,"building":"iron","game_link":"\/game.php?village=38859&amp;screen=iron","image":"<img src=\"https:\/\/dsde.innogamescdn.com\/asset\/e94cf8a0\/graphic\/buildings\/mid\/iron1.webp\" title=\"\" alt=\"\" class=\"bmain_list_img\" \/>","name":"Eisenmine"},{"building_level":3,"building":"farm","game_link":"\/game.php?village=38859&amp;screen=farm","image":"<img src=\"https:\/\/dsde.innogamescdn.com\/asset\/e94cf8a0\/graphic\/buildings\/mid\/farm1.webp\" title=\"\" alt=\"\" class=\"bmain_list_img\" \/>","name":"Bauernhof"},{"building_level":6,"building":"storage","game_link":"\/game.php?village=38859&amp;screen=storage","image":"<img src=\"https:\/\/dsde.innogamescdn.com\/asset\/e94cf8a0\/graphic\/buildings\/mid\/storage1.webp\" title=\"\" alt=\"\" class=\"bmain_list_img\" \/>","name":"Speicher"},{"building_level":2,"building":"hide","game_link":"\/game.php?village=38859&amp;screen=hide","image":"<img src=\"https:\/\/dsde.innogamescdn.com\/asset\/e94cf8a0\/graphic\/buildings\/mid\/hide1.webp\" title=\"\" alt=\"\" class=\"bmain_list_img\" \/>","name":"Versteck"},{"building_level":6,"building":"wall","game_link":"\/game.php?village=38859&amp;screen=wall","image":"<img src=\"https:\/\/dsde.innogamescdn.com\/asset\/e94cf8a0\/graphic\/buildings\/mid\/wall2.webp\" title=\"\" alt=\"\" class=\"bmain_list_img\" \/>","name":"Wall"}],"unlocked_rewards_count":4,"claimed":{"id":1701878,"player_id":1577504441,"building":"main","building_level":8,"status":"unlocked","reward":{"wood":150,"stone":150,"iron":100}}},"game_data":{"player":{"id":1577504441,"name":"FetterOrk","ally":"0","ally_level":null,"ally_member_count":null,"sitter":"0","sleep_start":"0","sitter_type":"normal","sleep_end":"0","sleep_last":"0","email_valid":"1","villages":"1","incomings":"0","supports":0,"knight_location":"38859","knight_unit":"1820913072","rank":6357,"points":"245","date_started":"1790326410","is_guest":"0","confirmation_skipping_hash":"3149267717","quest_progress":"0","points_formatted":"245","rank_formatted":"6<span class=\"grey\">.<\/span>357","pp":"1905","new_ally_application":0,"new_ally_invite":"0","new_buddy_request":"0","new_daily_bonus":"0","new_forum_post":0,"new_post_notification":0,"new_igm":"0","new_items":"0","new_report":"0","new_quest":"1"},"quest":{"use_questlines":true},"features":{"Premium":{"possible":true,"active":false},"AccountManager":{"possible":false,"active":false},"FarmAssistent":{"possible":true,"active":false}},"village":{"id":38859,"name":"FetterOrk's Dorf","display_name":"FetterOrk's Dorf (306|547) K53","wood":1148,"wood_prod":0.051946091001298,"wood_float":1148,"stone":1111,"stone_prod":0.051946091001298,"stone_ …[gekuerzt]

======================================================================
# 5  ART: Klick
Zeitpunkt: 26.9.2026, 14:08:11
Adresse:   #
======================================================================

text=Abholen | onclick= | html=<a href="#" class="btn btn-confirm-yes reward-system-claim-button" data-reward-id="1700393">Abholen</a>

======================================================================
# 6  ART: XHR
Zeitpunkt: 26.9.2026, 14:08:11
Adresse:   /game.php?village=38859&screen=new_quests&ajax=claim_reward
======================================================================

reward_id=1700393&h=35a874f3

======================================================================
# 7  ART: XHR-Antwort
Zeitpunkt: 26.9.2026, 14:08:11
Adresse:   /game.php?village=38859&screen=new_quests&ajax=claim_reward
======================================================================

HTTP 200 :: {"response":{"rewards":[{"id":1700492,"player_id":1577504441,"building":"wall","building_level":3,"status":"unlocked","reward":{"wood":150,"stone":150,"iron":100}}],"rewards_all":{"wall":{"ids":[1700492,1700849,1701370],"wood":450,"stone":450,"iron":300,"count":3}},"rewards_html":{"1700492":{"game_link":"\/game.php?village=38859&amp;screen=wall","image":"<img src=\"https:\/\/dsde.innogamescdn.com\/asset\/e94cf8a0\/graphic\/buildings\/mid\/wall1.webp\" title=\"\" alt=\"\" class=\"bmain_list_img\" \/>","name":"Wall"}},"unlockable_rewards":[{"building_level":9,"building":"main","game_link":"\/game.php?village=38859&amp;screen=main","image":"<img src=\"https:\/\/dsde.innogamescdn.com\/asset\/e94cf8a0\/graphic\/buildings\/mid\/main2.webp\" title=\"\" alt=\"\" class=\"bmain_list_img\" \/>","name":"Hauptgeb\u00e4ude"},{"building_level":6,"building":"barracks","game_link":"\/game.php?village=38859&amp;screen=barracks","image":"<img src=\"https:\/\/dsde.innogamescdn.com\/asset\/e94cf8a0\/graphic\/buildings\/mid\/barracks2.webp\" title=\"\" alt=\"\" class=\"bmain_list_img\" \/>","name":"Kaserne"},{"building_level":1,"building":"stable","game_link":"\/game.php?village=38859&amp;screen=stable","image":"<img src=\"https:\/\/dsde.innogamescdn.com\/asset\/e94cf8a0\/graphic\/buildings\/mid\/stable1.webp\" title=\"\" alt=\"\" class=\"bmain_list_img\" \/>","name":"Stall"},{"building_level":1,"building":"garage","game_link":"\/game.php?village=38859&amp;screen=garage","image":"<img src=\"https:\/\/dsde.innogamescdn.com\/asset\/e94cf8a0\/graphic\/buildings\/mid\/garage1.webp\" title=\"\" alt=\"\" class=\"bmain_list_img\" \/>","name":"Werkstatt"},{"building_level":1,"building":"watchtower","game_link":"\/game.php?village=38859&amp;screen=watchtower","image":"<img src=\"https:\/\/dsde.innogamescdn.com\/asset\/e94cf8a0\/graphic\/buildings\/mid\/watchtower1.webp\" title=\"\" alt=\"\" class=\"bmain_list_img\" \/>","name":"Wachturm"},{"building_level":1,"building":"snob","game_link":"\/game.php?village=38859&amp;screen=snob","image":"<img src=\"https:\/\/dsde.innogamescdn.com\/asset\/e94cf8a0\/graphic\/buildings\/mid\/snob1.webp\" title=\"\" alt=\"\" class=\"bmain_list_img\" \/>","name":"Adelshof"},{"building_level":2,"building":"smith","game_link":"\/game.php?village=38859&amp;screen=smith","image":"<img src=\"https:\/\/dsde.innogamescdn.com\/asset\/e94cf8a0\/graphic\/buildings\/mid\/smith1.webp\" title=\"\" alt=\"\" class=\"bmain_list_img\" \/>","name":"Schmiede"},{"building_level":2,"building":"market","game_link":"\/game.php?village=38859&amp;screen=market","image":"<img src=\"https:\/\/dsde.innogamescdn.com\/asset\/e94cf8a0\/graphic\/buildings\/mid\/market1.webp\" title=\"\" alt=\"\" class=\"bmain_list_img\" \/>","name":"Marktplatz"},{"building_level":11,"building":"wood","game_link":"\/game.php?village=38859&amp;screen=wood","image":"<img src=\"https:\/\/dsde.innogamescdn.com\/asset\/e94cf8a0\/graphic\/buildings\/mid\/wood2.webp\" title=\"\" alt=\"\" class=\"bmain_list_img\" \/>","name":"Holzf\u00e4llerlager"},{"building_level":11,"building":"stone","game_link":"\/game.php?village=38859&amp;screen=stone","image":"<img src=\"https:\/\/dsde.innogamescdn.com\/asset\/e94cf8a0\/graphic\/buildings\/mid\/stone2.webp\" title=\"\" alt=\"\" class=\"bmain_list_img\" \/>","name":"Lehmgrube"},{"building_level":9,"building":"iron","game_link":"\/game.php?village=38859&amp;screen=iron","image":"<img src=\"https:\/\/dsde.innogamescdn.com\/asset\/e94cf8a0\/graphic\/buildings\/mid\/iron1.webp\" title=\"\" alt=\"\" class=\"bmain_list_img\" \/>","name":"Eisenmine"},{"building_level":3,"building":"farm","game_link":"\/game.php?village=38859&amp;screen=farm","image":"<img src=\"https:\/\/dsde.innogamescdn.com\/asset\/e94cf8a0\/graphic\/buildings\/mid\/farm1.webp\" title=\"\" alt=\"\" class=\"bmain_list_img\" \/>","name":"Bauernhof"},{"building_level":6,"building":"storage","game_link":"\/game.php?village=38859&amp;screen=storage","image":"<img src=\"https:\/\/dsde.innogamescdn.com\/asset\/e94cf8a0\/graphic\/buildings\/mid\/storage1.webp\" title=\"\" alt=\"\" class=\"bmain_list_img\" \/>","name":"Speicher"},{"building_level":2,"building":"hide","game_link":"\/game.php?village=38859&amp;screen=hide","image":"<img src=\"https:\/\/dsde.innogamescdn.com\/asset\/e94cf8a0\/graphic\/buildings\/mid\/hide1.webp\" title=\"\" alt=\"\" class=\"bmain_list_img\" \/>","name":"Versteck"},{"building_level":6,"building":"wall","game_link":"\/game.php?village=38859&amp;screen=wall","image":"<img src=\"https:\/\/dsde.innogamescdn.com\/asset\/e94cf8a0\/graphic\/buildings\/mid\/wall2.webp\" title=\"\" alt=\"\" class=\"bmain_list_img\" \/>","name":"Wall"}],"unlocked_rewards_count":3,"claimed":{"id":1700393,"player_id":1577504441,"building":"wall","building_level":2,"status":"unlocked","reward":{"wood":150,"stone":150,"iron":100}}},"game_data":{"player":{"id":1577504441,"name":"FetterOrk","ally":"0","ally_level":null,"ally_member_count":null,"sitter":"0","sleep_start":"0","sitter_type":"normal","sleep_end":"0","sleep_last":"0","email_valid":"1","villages":"1","incomings":"0","supports":0,"knight_location":"38859","knight_unit":"1820913072","rank":6357,"points":"245","date_started":"1790326410","is_guest":"0","confirmation_skipping_hash":"3149267717","quest_progress":"0","points_formatted":"245","rank_formatted":"6<span class=\"grey\">.<\/span>357","pp":"1905","new_ally_application":0,"new_ally_invite":"0","new_buddy_request":"0","new_daily_bonus":"0","new_forum_post":0,"new_post_notification":0,"new_igm":"0","new_items":"0","new_report":"0","new_quest":"1"},"quest":{"use_questlines":true},"features":{"Premium":{"possible":true,"active":false},"AccountManager":{"possible":false,"active":false},"FarmAssistent":{"possible":true,"active":false}},"village":{"id":38859,"name":"FetterOrk's Dorf","display_name":"FetterOrk's Dorf (306|547) K53","wood":1300,"wood_prod":0.051946091001298,"wood_float":1300,"stone":1263,"stone_prod":0.051946091001298,"stone_float":1 …[gekuerzt]

======================================================================
# 8  ART: Klick
Zeitpunkt: 26.9.2026, 14:13:55
Adresse:   /game.php?village=38859&screen=new_quests&mode=quest&quest_id=1215
======================================================================

text=Zusätzliches Einkommen | onclick= | html=<a href="/game.php?village=38859&amp;screen=new_quests&amp;mode=quest&amp;quest_id=1215">Zusätzliches Einkommen</a>
```
