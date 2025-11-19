import { NextRequest, NextResponse } from 'next/server';

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
const cameras: Camera[] = [];

export async function GET(
  request: NextRequest,
  { params }: { params: Promise<{ camera_id: string }> }
) {
  try {
    const { camera_id: cameraId } = await params;
    const apiKey = request.headers.get('X-API-Key');

    if (!apiKey) {
      return NextResponse.json(
        { success: false, error: 'API key is required' },
        { status: 401 }
      );
    }

    const camera = cameras.find(cam =>
      cam.cameraId === cameraId && cam.apiKeyHash === require('crypto').createHash('sha256').update(apiKey).digest('hex')
    );

    if (!camera) {
      return NextResponse.json(
        { success: false, error: 'Camera not found or invalid API key' },
        { status: 404 }
      );
    }

    // Simulate random status updates for demo
    const batteryLevel = Math.floor(Math.random() * 100);
    const signalStrength = Math.floor(Math.random() * 5) + 1;

    return NextResponse.json({
      success: true,
      data: {
        cameraId: camera.cameraId,
        isOnline: camera.isOnline,
        lastCapture: camera.lastCaptureAt,
        batteryLevel,
        signalStrength
      }
    });
  } catch (error) {
    console.error('Camera status error:', error);
    return NextResponse.json(
      { success: false, error: 'Internal server error' },
      { status: 500 }
    );
  }
}