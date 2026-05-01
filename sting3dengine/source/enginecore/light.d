struct Light{
    float[3] mColor = [1.0f, 1.0f, 1.0f];
    float[3] mPosition = [0.1, 0.0, 0.1];
    float mAmbientIntensity = 2.0f;
    float mSpecularIntensity = 0.5f;
    float mSpecularExponent = 32.0f;
};
