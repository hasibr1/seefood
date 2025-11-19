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

    // Check if user already exists
    const existingUser = users.find(user => user.email === email);
    if (existingUser) {
      return NextResponse.json(
        { success: false, error: 'User already exists with this email' },
        { status: 409 }
      );
    }

    // Create new user
    const newUser: User = {
      id: crypto.randomUUID(),
      email,
      passwordHash: hashPassword(password),
      createdAt: new Date()
    };

    users.push(newUser);

    return NextResponse.json({
      success: true,
      data: {
        id: newUser.id,
        email: newUser.email,
        createdAt: newUser.createdAt
      }
    });
  } catch (error) {
    console.error('Registration error:', error);
    return NextResponse.json(
      { success: false, error: 'Internal server error' },
      { status: 500 }
    );
  }
}