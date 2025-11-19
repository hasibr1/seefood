import { NextRequest, NextResponse } from 'next/server';
import crypto from 'crypto';

interface User {
  id: string;
  email: string;
  passwordHash: string;
  createdAt: Date;
}

// In-memory storage for demo purposes
// In production, use a proper database
const users: User[] = [];

function hashPassword(password: string): string {
  return crypto.createHash('sha256').update(password + 'salt').digest('hex');
}

export async function POST(request: NextRequest) {
  try {
    const { email, password } = await request.json();

    if (!email || !password) {
      return NextResponse.json(
        { success: false, error: 'Email and password are required' },
        { status: 400 }
      );
    }

    // Find user by email
    const user = users.find(u => u.email === email);
    if (!user) {
      return NextResponse.json(
        { success: false, error: 'Invalid credentials' },
        { status: 401 }
      );
    }

    // Verify password
    const hashedPassword = hashPassword(password);
    if (user.passwordHash !== hashedPassword) {
      return NextResponse.json(
        { success: false, error: 'Invalid credentials' },
        { status: 401 }
      );
    }

    // Generate API key (in production, use JWT or proper session management)
    const apiKey = crypto.randomBytes(32).toString('hex');

    return NextResponse.json({
      success: true,
      data: {
        user: {
          id: user.id,
          email: user.email,
          createdAt: user.createdAt
        },
        apiKey
      }
    });
  } catch (error) {
    console.error('Login error:', error);
    return NextResponse.json(
      { success: false, error: 'Internal server error' },
      { status: 500 }
    );
  }
}