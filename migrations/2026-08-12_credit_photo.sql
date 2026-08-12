-- ═══════════════════════════════════════════════════════════════════════════
--  credit_photo — champ photographe dans le dépôt artiste (Sur nos murs)
--  2026-08-12 · directive Cédric 2026-08-10 via Apollon → Héphaïstos
-- ═══════════════════════════════════════════════════════════════════════════

ALTER TABLE public.artistes_murs
  ADD COLUMN IF NOT EXISTS credit_photo text;

CREATE OR REPLACE FUNCTION public.maj_dossier_murs(p_token text, p_payload jsonb)
 RETURNS artistes_murs
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare v_row public.artistes_murs;
begin
  update public.artistes_murs set
    bio              = case when p_payload ? 'bio'              then p_payload->>'bio' else bio end,
    titre_expo       = case when p_payload ? 'titre_expo'       then p_payload->>'titre_expo' else titre_expo end,
    technique        = case when p_payload ? 'technique'        then p_payload->>'technique' else technique end,
    dimensions_notes = case when p_payload ? 'dimensions_notes' then p_payload->>'dimensions_notes' else dimensions_notes end,
    cellulaire       = case when p_payload ? 'cellulaire'       then p_payload->>'cellulaire' else cellulaire end,
    instagram        = case when p_payload ? 'instagram'        then p_payload->>'instagram' else instagram end,
    facebook         = case when p_payload ? 'facebook'         then p_payload->>'facebook' else facebook end,
    site_web         = case when p_payload ? 'site_web'         then p_payload->>'site_web' else site_web end,
    nb_oeuvres       = case when p_payload ? 'nb_oeuvres'       then nullif(p_payload->>'nb_oeuvres','')::int else nb_oeuvres end,
    photo_artiste_path = case when p_payload ? 'photo_artiste_path' then p_payload->>'photo_artiste_path' else photo_artiste_path end,
    photos_oeuvres_paths = case when jsonb_typeof(p_payload->'photos_oeuvres_paths')='array' then (select coalesce(array_agg(x),'{}'::text[]) from jsonb_array_elements_text(p_payload->'photos_oeuvres_paths') x) else photos_oeuvres_paths end,
    signature_acceptee = case when p_payload ? 'signature_acceptee' then (p_payload->>'signature_acceptee')::boolean else signature_acceptee end,
    signature_nom    = case when p_payload ? 'signature_nom'    then p_payload->>'signature_nom' else signature_nom end,
    signature_le     = case when p_payload ? 'signature_le'     then nullif(p_payload->>'signature_le','')::timestamptz else signature_le end,
    credit_photo     = case when p_payload ? 'credit_photo'     then p_payload->>'credit_photo' else credit_photo end,
    statut           = case when p_payload->>'statut' in ('candidature_complete','depot_complet') then p_payload->>'statut' else statut end,
    maj_le           = now()
  where token_depot = p_token
  returning * into v_row;
  if not found then raise exception 'token inconnu'; end if;
  return v_row;
end;
$function$;
