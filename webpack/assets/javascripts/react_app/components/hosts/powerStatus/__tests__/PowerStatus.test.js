import React from 'react';
import { screen } from '@testing-library/react';
import '@testing-library/jest-dom';
import { rtlHelpers } from '../../../../common/testHelpers';
import PowerStatus from '../PowerStatus';
import ConnectedPowerStatus from '../index';
import {
  pendingProps,
  errorProps,
  successProps,
  successWithOffProps,
  pendingStore,
  errorStore,
  resolvedStore,
  resolvedStoreWithOff,
  serverProps,
} from '../PowerStatus.fixtures';
import { selectState, selectTitle } from '../PowerStatusSelectors';
import { key } from '../PowerStatus.fixtures';

describe('PowerStatusInner', () => {
  it('should render power status with spinner', () => {
    const { container } = rtlHelpers.renderWithStore(
      <PowerStatus {...pendingProps} />
    );

    // Check for loader root element
    const loaderRoot = container.querySelector('.loader-root');
    expect(loaderRoot).toBeInTheDocument();
    // Status span should not be present when loading
    expect(screen.queryByTitle(/./)).not.toBeInTheDocument();
  });

  it('should render power status with error', () => {
    rtlHelpers.renderWithStore(<PowerStatus {...errorProps} />);

    const statusSpan = screen.getByTitle(errorProps.title);
    expect(statusSpan).toBeInTheDocument();
    expect(statusSpan).toHaveClass('fa', 'fa-power-off', 'host-power-status', 'na');
  });

  it('should render power status when resolved with on', () => {
    rtlHelpers.renderWithStore(<PowerStatus {...successProps} />);

    const statusSpan = screen.getByTitle(successProps.title);
    expect(statusSpan).toBeInTheDocument();
    expect(statusSpan).toHaveClass('fa', 'fa-power-off', 'host-power-status', 'on');
  });

  it('should render power status when resolved with off', () => {
    rtlHelpers.renderWithStore(<PowerStatus {...successWithOffProps} />);

    const statusSpan = screen.getByTitle(successWithOffProps.title);
    expect(statusSpan).toBeInTheDocument();
    expect(statusSpan).toHaveClass('fa', 'fa-power-off', 'host-power-status', 'off');
  });
});

describe('ConnectedPowerStatus', () => {
  it('should render power status with spinner when pending', () => {
    const { container } = rtlHelpers.renderWithStore(
      <ConnectedPowerStatus {...serverProps} />,
      pendingStore
    );

    const loaderRoot = container.querySelector('.loader-root');
    expect(loaderRoot).toBeInTheDocument();
    expect(screen.queryByTitle(/./)).not.toBeInTheDocument();
  });

  it('should render power status with error when API error occurs', async () => {
    // Verify selectors work correctly with error store
    const state = selectState(errorStore, key);
    const title = selectTitle(errorStore, key);
    expect(state).toBe('na');
    expect(title).toBe('some_error');
    rtlHelpers.mockAPIGetFailure({message: 'some_error'}, 500);
    const { container } = rtlHelpers.renderWithStore(
      <ConnectedPowerStatus {...serverProps} />,
      errorStore
    );
    const statusSpan = await screen.findByTitle('some_error');
    expect(statusSpan).toBeInTheDocument();
    expect(statusSpan).toHaveClass('fa', 'fa-power-off', 'host-power-status', 'na');
  });

  it('should render power status when resolved with on', () => {
    rtlHelpers.renderWithStore(
      <ConnectedPowerStatus {...serverProps} />,
      resolvedStore
    );

    const statusSpan = screen.getByTitle(successProps.title);
    expect(statusSpan).toBeInTheDocument();
    expect(statusSpan).toHaveClass('fa', 'fa-power-off', 'host-power-status', 'on');
  });

  it('should render power status when resolved with off', () => {
    rtlHelpers.renderWithStore(
      <ConnectedPowerStatus {...serverProps} />,
      resolvedStoreWithOff
    );

    const statusSpan = screen.getByTitle(successWithOffProps.title);
    expect(statusSpan).toBeInTheDocument();
    expect(statusSpan).toHaveClass('fa', 'fa-power-off', 'host-power-status', 'off');
  });
});
