import { NextRequest, NextResponse } from 'next/server';
import crypto from 'crypto';

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

interface FridgeImage {
  id: string;
  cameraId: string;
  imageUrl: string;
  thumbnailUrl: string;
  fileSize: number;
  capturedAt: Date;
}

// In-memory storage for demo purposes
const cameras: Camera[] = [];
const images: FridgeImage[] = [];

export async function POST(
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
      cam.cameraId === cameraId && cam.apiKeyHash === crypto.createHash('sha256').update(apiKey).digest('hex')
    );

    if (!camera) {
      return NextResponse.json(
        { success: false, error: 'Camera not found or invalid API key' },
        { status: 404 }
      );
    }

    // Simulate camera capture process
    // In production, this would trigger the actual camera hardware
    if (!camera.isOnline) {
      return NextResponse.json(
        { success: false, error: 'Camera is offline' },
        { status: 503 }
      );
    }

    // Simulate capture delay
    await new Promise(resolve => setTimeout(resolve, 2000));

    // Generate mock image data
    const imageId = crypto.randomUUID();
    const capturedAt = new Date();
    const fileSize = Math.floor(Math.random() * 2000000) + 500000; // 0.5MB - 2.5MB

    // Mock image URLs (in production, these would be real stored images)
    const imageUrl = `https://storage.seefood.app/images/${imageId}.jpg`;
    const thumbnailUrl = `https://storage.seefood.app/thumbnails/${imageId}_thumb.jpg`;

    const newImage: FridgeImage = {
      id: imageId,
      cameraId,
      imageUrl,
      thumbnailUrl,
      fileSize,
      capturedAt
    };

    images.push(newImage);

    // Update camera status
    camera.lastCaptureAt = capturedAt;

    return NextResponse.json({
      success: true,
      data: {
        id: newImage.id,
        cameraId: newImage.cameraId,
        imageUrl: newImage.imageUrl,
        thumbnailUrl: newImage.thumbnailUrl,
        fileSize: newImage.fileSize,
        capturedAt: newImage.capturedAt
      }
    });
  } catch (error) {
    console.error('Image capture error:', error);
    return NextResponse.json(
      { success: false, error: 'Internal server error' },
      { status: 500 }
    );
  }
}