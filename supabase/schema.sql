-- Home Inventory Database Schema for Supabase
-- Run this in the Supabase SQL Editor

-- Enable RLS on all tables
-- Houses
CREATE TABLE IF NOT EXISTS public.houses (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    name TEXT NOT NULL,
    created_by UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE public.houses ENABLE ROW LEVEL SECURITY;

-- Profiles
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    nickname TEXT NOT NULL UNIQUE,
    email TEXT NOT NULL UNIQUE,
    house_id UUID REFERENCES public.houses(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- Rooms
CREATE TABLE IF NOT EXISTS public.rooms (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    name TEXT NOT NULL,
    house_id UUID NOT NULL REFERENCES public.houses(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE public.rooms ENABLE ROW LEVEL SECURITY;

-- Categories
CREATE TABLE IF NOT EXISTS public.categories (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    name TEXT NOT NULL,
    description TEXT,
    house_id UUID NOT NULL REFERENCES public.houses(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE public.categories ENABLE ROW LEVEL SECURITY;

-- Products
CREATE TABLE IF NOT EXISTS public.products (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    name TEXT NOT NULL,
    brand TEXT,
    note TEXT,
    quantity INTEGER NOT NULL DEFAULT 1,
    price NUMERIC(10,2),
    room_id UUID NOT NULL REFERENCES public.rooms(id) ON DELETE CASCADE,
    category_id UUID REFERENCES public.categories(id) ON DELETE SET NULL,
    house_id UUID NOT NULL REFERENCES public.houses(id) ON DELETE CASCADE,
    status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'terminated')),
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE public.products ENABLE ROW LEVEL SECURITY;

-- Product History
CREATE TABLE IF NOT EXISTS public.product_history (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    product_id UUID NOT NULL REFERENCES public.products(id) ON DELETE CASCADE,
    action TEXT NOT NULL CHECK (action IN ('created', 'updated', 'moved', 'terminated')),
    details JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE public.product_history ENABLE ROW LEVEL SECURITY;

-- Invitations
CREATE TABLE IF NOT EXISTS public.invitations (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    from_user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    to_email TEXT NOT NULL,
    house_id UUID NOT NULL REFERENCES public.houses(id) ON DELETE CASCADE,
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'rejected')),
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE public.invitations ENABLE ROW LEVEL SECURITY;

-- RLS Policies

-- Houses: readable by creator or members, creatable by authenticated
CREATE POLICY "Houses readable by members"
    ON public.houses
    FOR SELECT
    USING (
        created_by = auth.uid()
        OR EXISTS (
            SELECT 1 FROM public.profiles
            WHERE profiles.house_id = houses.id
            AND profiles.id = auth.uid()
        )
    );

CREATE POLICY "Houses insertable by authenticated"
    ON public.houses
    FOR INSERT
    WITH CHECK (created_by = auth.uid());

-- Profiles: users can read/update their own
CREATE POLICY "Profiles readable by self"
    ON public.profiles
    FOR SELECT
    USING (id = auth.uid());

CREATE POLICY "Profiles insertable by self"
    ON public.profiles
    FOR INSERT
    WITH CHECK (id = auth.uid());

CREATE POLICY "Profiles updatable by self"
    ON public.profiles
    FOR UPDATE
    USING (id = auth.uid());

-- Rooms: readable/managable by house members
CREATE POLICY "Rooms readable by house members"
    ON public.rooms
    FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.profiles
            WHERE profiles.house_id = rooms.house_id
            AND profiles.id = auth.uid()
        )
    );

CREATE POLICY "Rooms insertable by house members"
    ON public.rooms
    FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.profiles
            WHERE profiles.house_id = rooms.house_id
            AND profiles.id = auth.uid()
        )
    );

CREATE POLICY "Rooms updatable by house members"
    ON public.rooms
    FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM public.profiles
            WHERE profiles.house_id = rooms.house_id
            AND profiles.id = auth.uid()
        )
    );

CREATE POLICY "Rooms deletable by house members"
    ON public.rooms
    FOR DELETE
    USING (
        EXISTS (
            SELECT 1 FROM public.profiles
            WHERE profiles.house_id = rooms.house_id
            AND profiles.id = auth.uid()
        )
    );

-- Categories: readable/managable by house members
CREATE POLICY "Categories readable by house members"
    ON public.categories
    FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.profiles
            WHERE profiles.house_id = categories.house_id
            AND profiles.id = auth.uid()
        )
    );

CREATE POLICY "Categories insertable by house members"
    ON public.categories
    FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.profiles
            WHERE profiles.house_id = categories.house_id
            AND profiles.id = auth.uid()
        )
    );

CREATE POLICY "Categories updatable by house members"
    ON public.categories
    FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM public.profiles
            WHERE profiles.house_id = categories.house_id
            AND profiles.id = auth.uid()
        )
    );

CREATE POLICY "Categories deletable by house members"
    ON public.categories
    FOR DELETE
    USING (
        EXISTS (
            SELECT 1 FROM public.profiles
            WHERE profiles.house_id = categories.house_id
            AND profiles.id = auth.uid()
        )
    );

-- Products: readable/managable by house members
CREATE POLICY "Products readable by house members"
    ON public.products
    FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.profiles
            WHERE profiles.house_id = products.house_id
            AND profiles.id = auth.uid()
        )
    );

CREATE POLICY "Products insertable by house members"
    ON public.products
    FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.profiles
            WHERE profiles.house_id = products.house_id
            AND profiles.id = auth.uid()
        )
    );

CREATE POLICY "Products updatable by house members"
    ON public.products
    FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM public.profiles
            WHERE profiles.house_id = products.house_id
            AND profiles.id = auth.uid()
        )
    );

CREATE POLICY "Products deletable by house members"
    ON public.products
    FOR DELETE
    USING (
        EXISTS (
            SELECT 1 FROM public.profiles
            WHERE profiles.house_id = products.house_id
            AND profiles.id = auth.uid()
        )
    );

-- Product History: readable by house members (via product join)
CREATE POLICY "Product history readable by house members"
    ON public.product_history
    FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.products
            JOIN public.profiles ON products.house_id = profiles.house_id
            WHERE products.id = product_history.product_id
            AND profiles.id = auth.uid()
        )
    );

CREATE POLICY "Product history insertable by house members"
    ON public.product_history
    FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.products
            JOIN public.profiles ON products.house_id = profiles.house_id
            WHERE products.id = product_history.product_id
            AND profiles.id = auth.uid()
        )
    );

-- Invitations: readable by involved parties
CREATE POLICY "Invitations readable by involved"
    ON public.invitations
    FOR SELECT
    USING (
        from_user_id = auth.uid()
        OR EXISTS (
            SELECT 1 FROM public.houses
            JOIN public.profiles ON houses.created_by = profiles.id
            WHERE houses.id = invitations.house_id
            AND profiles.id = auth.uid()
        )
    );

CREATE POLICY "Invitations insertable by authenticated"
    ON public.invitations
    FOR INSERT
    WITH CHECK (from_user_id = auth.uid());

CREATE POLICY "Invitations updatable by house creator"
    ON public.invitations
    FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM public.houses
            WHERE houses.id = invitations.house_id
            AND houses.created_by = auth.uid()
        )
    );

-- Trigger to auto-update products.updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ language 'plpgsql';

DROP TRIGGER IF EXISTS update_products_updated_at ON public.products;
CREATE TRIGGER update_products_updated_at
    BEFORE UPDATE ON public.products
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_invitations_updated_at ON public.invitations;
CREATE TRIGGER update_invitations_updated_at
    BEFORE UPDATE ON public.invitations
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();
