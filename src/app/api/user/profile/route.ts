import { NextRequest, NextResponse } from 'next/server';
import crypto from 'crypto';

interface User {
  id: string;
  email: string;
  passwordHash: string;
  createdAt: Date;
}

interface Camera {
  id: string;
  userId: string;
  cameraId: string;
  fridgeName: string;
  apiKeyHash: string;
  isOnline: boolean;
  lastCaptureAt: Date | null;
  createdAt: Date;
}

// In-memory storage for demo purposes
const users: User[] = [];
const cameras: Camera[] = [];

export async function GET(request: NextRequest) {
  try {
    const apiKey = request.headers.get('X-API-Key');

    if (!apiKey) {
      return NextResponse.json(
        { success: false, error: 'API key is required' },
        { status: 401 }
      );
    }

    // Find user by API key (simplified for demo)
    // In production, implement proper API key to user mapping
    const user = users[0]; // Simplified for demo

    if (!user) {
      return NextResponse.json(
        { success: false, error: 'User not found' },
        { status: 404 }
      );
    }

    // Get user's cameras
    const userCameras = cameras.filter(cam => cam.userId === user.id);

    return NextResponse.json({
      success: true,
      data: {
        user: {
          id: user.id,
          email: user.email,
          createdAt: user.createdAt
        },
        cameras: userCameras.map(cam => ({
          id: cam.id,
          cameraId: cam.cameraId,
          fridgeName: cam.fridgeName,
          isOnline: cam.isOnline,
          lastCaptureAt: cam.lastCaptureAt,
          createdAt: cam.createdAt
        }))
      }
    });
  } catch (error) {
    console.error('User profile error:', error);
    return NextResponse.json(
      { success: false, error: 'Internal server error' },
      { status: 500 }
    );
  }
}