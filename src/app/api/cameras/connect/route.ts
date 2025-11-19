import { NextRequest, NextResponse } from 'next/server';
import crypto from 'crypto';

interface QRCodeData {
  camera_id: string;
  setup_token: string;
  wifi_ssid: string;
  api_endpoint: string;
}

interface Camera {
  id: string;
  userId: string;
  cameraId: string;
  fridgeName: string;
  apiKeyHash: string;
  setupToken: string;
  setupTokenExpiresAt: Date;
  isOnline: boolean;
  lastCaptureAt: Date | null;
  createdAt: Date;
}

// In-memory storage for demo purposes
const cameras: Camera[] = [];
const setupTokens = new Map<string, { cameraId: string; expiresAt: Date }>();

export async function POST(request: NextRequest) {
  try {
    const { setupToken, userId } = await request.json();

    if (!setupToken || !userId) {
      return NextResponse.json(
        { success: false, error: 'Setup token and user ID are required' },
        { status: 400 }
      );
    }

    // Check if setup token is valid
    const tokenData = setupTokens.get(setupToken);
    if (!tokenData || tokenData.expiresAt < new Date()) {
      return NextResponse.json(
        { success: false, error: 'Invalid or expired setup token' },
        { status: 401 }
      );
    }

    // Check if camera is already registered
    const existingCamera = cameras.find(cam => cam.cameraId === tokenData.cameraId);
    if (existingCamera) {
      return NextResponse.json(
        { success: false, error: 'Camera already registered' },
        { status: 409 }
      );
    }

    // Generate API key for the camera
    const apiKey = crypto.randomBytes(32).toString('hex');
    const apiKeyHash = crypto.createHash('sha256').update(apiKey).digest('hex');

    // Create new camera record
    const newCamera: Camera = {
      id: crypto.randomUUID(),
      userId,
      cameraId: tokenData.cameraId,
      fridgeName: 'My Fridge',
      apiKeyHash,
      setupToken,
      setupTokenExpiresAt: tokenData.expiresAt,
      isOnline: false,
      lastCaptureAt: null,
      createdAt: new Date()
    };

    cameras.push(newCamera);

    // Remove the used setup token
    setupTokens.delete(setupToken);

    return NextResponse.json({
      success: true,
      data: {
        cameraId: newCamera.cameraId,
        fridgeName: newCamera.fridgeName,
        apiKey
      }
    });
  } catch (error) {
    console.error('Camera connection error:', error);
    return NextResponse.json(
      { success: false, error: 'Internal server error' },
      { status: 500 }
    );
  }
}

// Helper function to generate setup tokens (for testing)
export async function generateSetupToken(cameraId: string): Promise<string> {
  const setupToken = crypto.randomBytes(16).toString('hex');
  const expiresAt = new Date(Date.now() + 30 * 60 * 1000); // 30 minutes

  setupTokens.set(setupToken, {
    cameraId,
    expiresAt
  });

  return setupToken;
}