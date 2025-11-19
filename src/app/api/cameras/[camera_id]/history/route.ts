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
    const { searchParams } = new URL(request.url);

    if (!apiKey) {
      return NextResponse.json(
        { success: false, error: 'API key is required' },
        { status: 401 }
      );
    }

    // Parse query parameters
    const limit = parseInt(searchParams.get('limit') || '24');
    const offset = parseInt(searchParams.get('offset') || '0');

    // Get images from the last 24 hours for this camera
    const twentyFourHoursAgo = new Date(Date.now() - 24 * 60 * 60 * 1000);
    const cameraImages = images
      .filter(img => img.cameraId === cameraId && img.capturedAt >= twentyFourHoursAgo)
      .sort((a, b) => b.capturedAt.getTime() - a.capturedAt.getTime())
      .slice(offset, offset + limit);

    return NextResponse.json({
      success: true,
      data: {
        images: cameraImages,
        total: cameraImages.length,
        limit,
        offset
      }
    });
  } catch (error) {
    console.error('Image history error:', error);
    return NextResponse.json(
      { success: false, error: 'Internal server error' },
      { status: 500 }
    );
  }
}