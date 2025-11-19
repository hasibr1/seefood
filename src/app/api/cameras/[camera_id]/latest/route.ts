import { NextRequest, NextResponse } from 'next/server';
import crypto from 'crypto';

interface FridgeImage {
  id: string;
  cameraId: string;
  imageUrl: string;
  thumbnailUrl: string;
  fileSize: number;
  capturedAt: Date;
}

// In-memory storage for demo purposes
const images: FridgeImage[] = [];

export async function GET(
  request: NextRequest,
  { params }: { params: { camera_id: string } }
) {
  try {
    const cameraId = params.camera_id;
    const apiKey = request.headers.get('X-API-Key');

    if (!apiKey) {
      return NextResponse.json(
        { success: false, error: 'API key is required' },
        { status: 401 }
      );
    }

    // Find the latest image for this camera
    const latestImage = images
      .filter(img => img.cameraId === cameraId)
      .sort((a, b) => b.capturedAt.getTime() - a.capturedAt.getTime())[0];

    if (!latestImage) {
      return NextResponse.json(
        { success: false, error: 'No images found for this camera' },
        { status: 404 }
      );
    }

    return NextResponse.json({
      success: true,
      data: {
        id: latestImage.id,
        cameraId: latestImage.cameraId,
        imageUrl: latestImage.imageUrl,
        thumbnailUrl: latestImage.thumbnailUrl,
        fileSize: latestImage.fileSize,
        capturedAt: latestImage.capturedAt
      }
    });
  } catch (error) {
    console.error('Latest image error:', error);
    return NextResponse.json(
      { success: false, error: 'Internal server error' },
      { status: 500 }
    );
  }
}