/*
 * Copyright (c) 2021 Ronan LE MEILLAT
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the Software), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED AS IS, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
  */

#include <metal_stdlib>
#include <metal_types>

#define OVERLAP 64
#define CUT 688
#define BASESIZE 4096 //OVERLAP and CUT are based on this size


#define FOV 360.0f

using namespace metal;

enum Faces {
    TOP_LEFT,
    TOP_MIDDLE,
    TOP_RIGHT,
    BOTTOM_LEFT,
    BOTTOM_MIDDLE,
    BOTTOM_RIGHT,
    NB_FACES,
};

enum Direction {
    RIGHT,
    LEFT,
    UP,
    DOWN,
    FRONT,
    BACK,
    NB_DIRECTIONS,
};

enum Rotation {
    ROT_0,
    ROT_90,
    ROT_180,
    ROT_270,
    NB_ROTATIONS,
};

float2 rotate_cube_face(float2 uv, int rotation);
int2 transpose_gopromax_overlap(int2 xy, int2 dim);
float3 equirect_to_xyz(int2 xy,int2 size);
float2 xyz_to_cube(float3 xyz, thread int *direction, thread int *face);
float2 xyz_to_eac(float3 xyz, int2 size);

float2 rotate_cube_face(float2 uv, int rotation)
{
    float2 ret_uv;

    switch (rotation) {
    case ROT_0:
        ret_uv = uv;
        break;
    case ROT_90:
        ret_uv.x = -uv.y;
        ret_uv.y =  uv.x;
        break;
    case ROT_180:
        ret_uv.x = -uv.x;
        ret_uv.y = -uv.y;
        break;
    case ROT_270:
        ret_uv.x =  uv.y;
        ret_uv.y =  -uv.x;
        break;
    }
return ret_uv;
}

float3 equirect_to_xyz(int2 xy,int2 size)
{
    float3 xyz;
    float phi   = ((2.f * ((float)xy.x) + 0.5f) / ((float)size.x)  - 1.f) * M_PI_F ;
    float theta = ((2.f * ((float)xy.y) + 0.5f) / ((float)size.y) - 1.f) * M_PI_2_F;

    xyz.x = cos(theta) * sin(phi);
    xyz.y = sin(theta);
    xyz.z = cos(theta) * cos(phi);

    return xyz;
}

float2 xyz_to_cube(float3 xyz, thread int *direction, thread int *face)
{
    float phi   = atan2(xyz.x, xyz.z);
    float theta = asin(xyz.y);
    float phi_norm, theta_threshold;
    int face_rotation;
    float2 uv;
    //int direction;

    if (phi >= -M_PI_4_F && phi < M_PI_4_F) {
        *direction = FRONT;
        phi_norm = phi;
    } else if (phi >= -(M_PI_2_F + M_PI_4_F) && phi < -M_PI_4_F) {
        *direction = LEFT;
        phi_norm = phi + M_PI_2_F;
    } else if (phi >= M_PI_4_F && phi < M_PI_2_F + M_PI_4_F) {
        *direction = RIGHT;
        phi_norm = phi - M_PI_2_F;
    } else {
        *direction = BACK;
        phi_norm = phi + ((phi > 0.f) ? -M_PI_F : M_PI_F);
    }

    theta_threshold = atan(cos(phi_norm));
    if (theta > theta_threshold) {
        *direction = DOWN;
    } else if (theta < -theta_threshold) {
        *direction = UP;
    }
    
    theta_threshold = atan(cos(phi_norm));
    if (theta > theta_threshold) {
        *direction = DOWN;
    } else if (theta < -theta_threshold) {
        *direction = UP;
    }

    switch (*direction) {
    case RIGHT:
        uv.x = -xyz.z / xyz.x;
        uv.y =  xyz.y / xyz.x;
        *face = TOP_RIGHT;
        face_rotation = ROT_0;
        break;
    case LEFT:
        uv.x = -xyz.z / xyz.x;
        uv.y = -xyz.y / xyz.x;
        *face = TOP_LEFT;
        face_rotation = ROT_0;
        break;
    case UP:
        uv.x = -xyz.x / xyz.y;
        uv.y = -xyz.z / xyz.y;
        *face = BOTTOM_RIGHT;
        face_rotation = ROT_270;
        uv = rotate_cube_face(uv,face_rotation);
        break;
    case DOWN:
        uv.x =  xyz.x / xyz.y;
        uv.y = -xyz.z / xyz.y;
        *face = BOTTOM_LEFT;
        face_rotation = ROT_270;
        uv = rotate_cube_face(uv,face_rotation);
        break;
    case FRONT:
        uv.x =  xyz.x / xyz.z;
        uv.y =  xyz.y / xyz.z;
        *face = TOP_MIDDLE;
        face_rotation = ROT_0;
        break;
    case BACK:
        uv.x =  xyz.x / xyz.z;
        uv.y = -xyz.y / xyz.z;
        *face = BOTTOM_MIDDLE;
        face_rotation = ROT_90;
        uv = rotate_cube_face(uv,face_rotation);
        break;
    }
    
    return uv;
}

float2 xyz_to_eac(float3 xyz, int2 size)
{
    float pixel_pad = 2;
    float u_pad = pixel_pad / size.x;
    float v_pad = pixel_pad / size.y;

    int direction, face;
    int u_face, v_face;
    float2 uv = xyz_to_cube(xyz,&direction,&face);

    u_face = face % 3;
    v_face = face / 3;
    //eac expansion
    uv.x = M_2_PI_F * atan(uv.x) + 0.5f;
    uv.y = M_2_PI_F * atan(uv.y) + 0.5f;
    
    uv.x = (uv.x + u_face) * (1.f - 2.f * u_pad) / 3.f + u_pad;
    uv.y = uv.y * (0.5f - 2.f * v_pad) + v_pad + 0.5f * v_face;
    
    uv.x *= size.x;
    uv.y *= size.y;

    return uv;
}


int2 transpose_gopromax_overlap(int2 xy, int2 dim)
{
    int2 ret;
    int cut = dim.x*CUT/BASESIZE;
    int overlap = dim.x*OVERLAP/BASESIZE;
    if (xy.x<cut)
        {
            ret = xy;
        }
    else if ((xy.x>=cut) && (xy.x< (dim.x-cut)))
        {
            ret.x = xy.x+overlap;
            ret.y = xy.y;
        }
    else
        {
            ret.x = xy.x+2*overlap;
            ret.y = xy.y;
        }
    return ret;
}

kernel void gopromax_equirectangular(constant int& p_in_Width [[buffer (11)]], constant int& p_in_Height [[buffer (12)]],constant int& p_out_Width [[buffer (13)]], constant int& p_out_Height [[buffer (14)]], const device float* gopromax_stack [[buffer (0)]], device float* dst [[buffer (8)]], uint2 id [[ thread_position_in_grid ]])
{
    
    float4 val;
    int2 loc = {(int)id.x, (int)id.y};

    int2 dst_size = { p_out_Width,p_out_Height };
	int2 src_size = { p_in_Width,p_in_Height };
	int2 eac_size = { src_size.x - 2 * (src_size.x*OVERLAP / BASESIZE),dst_size.y };

	if (((loc.x < dst_size.x) && (loc.y < dst_size.y)))
	{    
		float3 xyz = equirect_to_xyz(loc, dst_size);

		float2 uv = xyz_to_eac(xyz, eac_size);

		int2 xy = (int2)(round(uv));

		xy = transpose_gopromax_overlap(xy, eac_size);

		if ((xy.x < src_size.x) && (xy.y < src_size.y))
		{
			const int index_in = (((dst_size.y - (xy.y + 1)) * dst_size.x) + (xy.x)) * 4;
			val.x = gopromax_stack[index_in + 0];
			val.y = gopromax_stack[index_in + 1];
			val.z = gopromax_stack[index_in + 2];
			val.w = gopromax_stack[index_in + 3];

			const int index = (((dst_size.y - (loc.y + 1)) * dst_size.x) + (loc.x)) * 4;
			dst[index + 0] = val.x;
			dst[index + 1] = val.y;
			dst[index + 2] = val.z;
			dst[index + 3] = val.w;
		}

	}

//identity test
/*
	if ((loc.x < dst_size.x) && (loc.y < dst_size.y))
	{
		int index = (((dst_size.y - (loc.y + 1)) * dst_size.x) + loc.x);
		{
			index *= 4;
			val.x = gopromax_stack[index + 0];
			val.y = gopromax_stack[index + 1];
			val.z = gopromax_stack[index + 2];
			val.w = gopromax_stack[index + 3];
			dst[index + 0] = val.x;
			dst[index + 1] = val.y;
			dst[index + 2] = val.z;
		}
	}
*/

}
