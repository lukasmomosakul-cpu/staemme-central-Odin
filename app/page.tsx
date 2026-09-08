'use client';

import { useEffect, useState, type FormEvent } from 'react';
import { supabase } from '../lib/supabase';
import GameNativeButton from '../components/GameNativeButton';

const APP_VERSION='1.1.26';
