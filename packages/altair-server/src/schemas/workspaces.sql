
create table workspaces (
  id bigint generated by default as identity primary key,
  -- user that owns/created the workspace
  owner_id uuid references auth.users not null,
  workspace_name text,
  inserted_at timestamp with time zone default timezone('utc'::text, now()) not null,
  updated_at timestamp with time zone default timezone('utc'::text, now()) not null
);
alter table workspaces enable row level security;

-- TODO: Check current plan limit
-- TODO: If user has subscription, check limit on subscription product
-- TODO: else check limit on default non-subscription product
create policy "Can only manage own workspaces." on workspaces
for all using (auth.uid() = owner_id);
create policy "enforce current product config on workspaces" on workspaces
for insert with check (
  (
    select workspace_count_limit
    from product_configs
    where id = 'noproduct'
  ) > (
    select count(id)
    from workspaces
    where owner_id = auth.uid()
  )
);

create trigger handle_updated_at before update on workspaces 
  for each row execute procedure moddatetime (updated_at);