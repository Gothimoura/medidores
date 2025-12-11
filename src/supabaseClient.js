import { createClient } from '@supabase/supabase-js'

// Vá no Supabase > Settings > API para pegar esses valores
const supabaseUrl = 'https://quzpakmslmcifvpjkdod.supabase.co'
const supabaseAnonKey = 'sb_publishable_RYDFebIRbTTMzO7U_zfihA_HWnkgW06'

export const supabase = createClient(supabaseUrl, supabaseAnonKey)