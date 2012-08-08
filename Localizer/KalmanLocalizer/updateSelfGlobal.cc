#include "kalmanlocalizer.ih"

void KalmanLocalizer::updateSelfGlobal()
{
  AgentModel& am = bats::SAgentModel::getInstance();
  
  VectorXd oldLocVel = me->posVelGlobal->getMu();
  Vector3d accLocal = am.getAcc();
  Vector3d accGlobal = d_globalRotation.linear() * accLocal;
  
  /*
   * Predict
   */
  
  // x_{t+1} = x_t + dt * v_t
  // v_{t+1} = v_t
  // So, F should be
  //
  // | 1  0  0 dt  0  0 |
  // | 0  1  0  0 dt  0 |
  // | 0  0  1  0  0 dt |
  // | 0  0  0  1  0  0 |
  // | 0  0  0  0  1  0 |
  // | 0  0  0  0  0  1 |
  //
  // TODO: use indeed v_t to predict
  MatrixXd F = MatrixXd::Identity(6, 6);
  //F.corner(TopRight, 3, 3).diagonal().setConstant(dt);

  // Assume no control
  // TODO: make this smarter by using actions of previous step
  //MatrixXd B = MatrixXd::Zero(6,6);
  //B.corner(BottomRight,3 ,3).diagonal().setConstant(dt);
  //VectorXd u = VectorXd::Zero(6);

  // Slight process noise to overcome lack of control data
  // TODO: tweak
  // this. Low value assumes no movement, large value means very
  // uncertain about movement, trust mostly vision
  MatrixXd Q = VectorXd::Constant(6, 0.0001).asDiagonal();
  
  rf<NormalDistribution> controlModel = new NormalDistribution(6);
  controlModel->init(VectorXd::Zero(6), Q);
  me->posVelGlobal->predict(F, controlModel);
  
  /*
   * Update
   */
  if (d_haveNewVisionData)
  {
    rf<NormalDistribution> obsModel = new NormalDistribution(6);
    Transform3d globalRotationTrans(d_globalRotation.matrix().transpose());
    
    for (rf<ObjectInfo> landmark : landmarks)
    {
      if (!landmark->isVisible)
        continue;

      VectorXd pos = landmark->posVelGlobal->getMu();
      //cerr << "landmark loc:" << endl << loc << endl;
      VectorXd meas = landmark->posVelRaw->getMu();
      //cerr << "raw meas:" << endl << meas << endl;
      MatrixXd sigma = landmark->posVelRaw->getSigma();

      VectorXd globalMeas = VectorXd::Zero(6);
      // Location part
      globalMeas.start<3>() = cutPositionVector(pos) - d_globalRotation * cutPositionVector(meas);
      // Velocity part
      globalMeas.end<3>() = (globalMeas - oldLocVel).start<3>();
      //cerr << "global meas:" << endl << globalMeas << endl;
      
      MatrixXd globalSigma = joinPositionAndVelocityMatrices(
        d_globalRotation.linear() * cutPositionMatrix(sigma) * globalRotationTrans.linear(),
        d_globalRotation.linear() * cutVelocityMatrix(sigma) * globalRotationTrans.linear());
      
      obsModel->init(globalMeas, globalSigma);
      me->posVelGlobal->update(obsModel);
    }
  }
  
  d_globalTranslation = Translation3d(cutPositionVector(me->posVelGlobal->getMu()));
  d_globalTransform = d_globalTranslation * d_globalRotation;
}