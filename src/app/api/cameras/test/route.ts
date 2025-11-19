import { NextRequest, NextResponse } from 'next/server';

interface Camera {
  id: string;
  userId: string;
  cameraId: string;
  fridgeName: string;
  apiKeyHash: string;
  isOnline: boolean;
  lastCaptureAt: Date | null;
}

// In-memory storage for demo purposes
const cameras: Camera[] = [];

function verifyApiKey(apiKey: string): Camera | null {
  const crypto = require('crypto');
  const apiKeyHash = crypto.createHash('sha256').update(apiKey).digest('hex');
  return cameras.find(cam => cam.apiKeyHash === apiKeyHash) || null;
}

export async function POST(request: NextRequest) {
  try {
    const apiKey = request.headers.get('X-API-Key');

    if (!apiKey) {
      return NextResponse.json(
        { success: false, error: 'API key is required' },
        { status: 401 }
      );
    }

    const camera = verifyApiKey(apiKey);
    if (!camera) {
      return NextResponse.json(
        { success: false, error: 'Invalid API key' },
        { status: 401 }
      );
    }

    // Simulate camera connectivity test
    // In production, this would actually ping the camera
    const isOnline = Math.random() > 0.2; // 80% success rate for demo

    if (isOnline) {
      camera.isOnline = true;
      camera.lastCaptureAt = new Date();
    } else {
      camera.isOnline = false;
    }

    return NextResponse.json({
      success: true,
      data: {
        cameraId: camera.cameraId,
        isOnline,
        testTime: new Date().toISOString()
      }
    });
  } catch (error) {
    console.error('Camera test error:', error);
    return NextResponse.json(
      { success: false, error: 'Internal server error' },
      { status: 500 }
    );
  }
}