DROP FUNCTION handle_new_user() CASCADE;

create function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = ''
as $$
begin
  insert into public.users (user_id)
  values (new.id);
  return new;
end;
$$;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();