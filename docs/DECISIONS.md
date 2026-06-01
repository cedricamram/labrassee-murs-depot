# Décisions — labrassee-murs-depot

## 2026-06-01 — Durcissement RLS et accès Supabase (protection des PII artistes)

**Contexte.** Les politiques RLS de la table `artistes_murs` étaient trop
permissives (`USING true` en lecture comme en écriture, malgré le nom « Lecture par
token »). Or la clé anon est, par nature, publiée en clair dans `index.html`.
N'importe quel visiteur pouvait donc aspirer l'ensemble des données personnelles des
artistes (courriels, cellulaires, notes) — y compris le `token_depot`, secret
d'édition — et écraser n'importe quelle candidature.

**Décision.** Le formulaire n'accède plus directement à la table pour la
lecture/écriture du dossier. Ces chemins passent désormais par des fonctions RPC
Supabase `SECURITY DEFINER`, vérifiant le token et limitées à une liste blanche de
colonnes :

- `get_dossier_murs(token)` — lecture du dossier. Le `token_depot` n'est plus relu
  par le client.
- `maj_dossier_murs(token, payload)` — mise à jour (statut limité à
  `candidature_complete` / `depot_complet` ; champs admin intouchables).
- `creer_candidature_murs(payload)` — création ; `token_depot` généré côté serveur,
  statut forcé à `candidature`.

Le calcul des dimanches d'accrochage libres continue de lire, en anon, uniquement
quatre colonnes non sensibles (`date_install`, `date_decrochage`,
`signature_acceptee`, `statut`), conservées dans la « vitrine » publique.

Les colonnes PII et le `token_depot` ne sont plus lisibles via la clé anon
(REVOKE/GRANT au niveau colonne, RLS conservée en lecture pour les seules colonnes
« vitrine »).

**Déploiement.** Uniquement `git push origin main` (intégration GitHub-Vercel).
Jamais de `vercel deploy`, `vercel --prod` ni d'outil de déploiement direct.
